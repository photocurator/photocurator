"""This module defines the Celery worker and the main task for processing images."""
from celery import Celery, states
from src.tasks import TASK_REGISTRY
from src.db import get_db_connection
import os
import importlib

broker_url = os.getenv("CELERY_BROKER_URL", "pyamqp://guest@localhost//")
backend_url = os.getenv("CELERY_RESULT_BACKEND", "rpc://")

app = Celery(
    "worker",
    broker=broker_url,
    backend=backend_url
)

def get_db_conn_and_cursor():
    """Gets a database connection and cursor.

    Returns:
        tuple: A tuple containing the database connection and cursor.
    """
    conn = get_db_connection()
    return conn, conn.cursor()

def close_db_conn_and_cursor(conn, cursor):
    """Closes the database connection and cursor.

    Args:
        conn (psycopg2.extensions.connection): The database connection.
        cursor (psycopg2.extensions.cursor): The database cursor.
    """
    if cursor:
        cursor.close()
    if conn:
        conn.close()

def register_tasks():
    """Dynamically imports all tasks from the `src/tasks` directory to ensure they are registered in the TASK_REGISTRY."""
    tasks_dir = os.path.join(os.path.dirname(__file__), "src", "tasks")
    for filename in os.listdir(tasks_dir):
        if filename.endswith(".py") and not filename.startswith("__"):
            module_name = f"src.tasks.{filename[:-3]}"
            importlib.import_module(module_name)

register_tasks()

@app.task(bind=True, max_retries=3, default_retry_delay=5)
def process_image(self, task_name: str, image_id: str, job_item_id: str):
    """The main Celery task for processing an image.

    This task retrieves the appropriate task class from the TASK_REGISTRY,
    updates the job item status in the database, runs the task, and handles
    retries and failures.

    Args:
        task_name (str): The name of the task to run.
        image_id (str): The ID of the image to process.
        job_item_id (str): The ID of the analysis job item.
    """
    conn, cur = None, None
    try:
        conn, cur = get_db_conn_and_cursor()

        cur.execute("UPDATE analysis_job_item SET item_status = 'processing', started_at = NOW() WHERE id = %s", (job_item_id,))
        conn.commit()

        task_class = TASK_REGISTRY.get(task_name)
        if not task_class:
            raise ValueError(f"Task '{task_name}' not found in registry.")

        task_instance = task_class()
        task_instance.run(image_id)

        cur.execute("UPDATE analysis_job_item SET item_status = 'completed', completed_at = NOW() WHERE id = %s", (job_item_id,))
        conn.commit()

    except Exception as exc:
        if conn and cur:
            conn.rollback() # Rollback any partial changes
            cur.execute(
                "UPDATE analysis_job_item SET error_message = %s WHERE id = %s",
                (str(exc), job_item_id)
            )
            conn.commit()

        try:
            raise self.retry(exc=exc)
        except self.MaxRetriesExceededError:
            if conn and cur:
                cur.execute("UPDATE analysis_job_item SET item_status = 'failed' WHERE id = %s", (job_item_id,))
                conn.commit()
            self.update_state(state=states.FAILURE, meta={'exc': exc})
    finally:
        close_db_conn_and_cursor(conn, cur)
