from celery import Celery, states
from src.tasks import TASK_REGISTRY
from src.db import get_db_connection
import os
import importlib

app = Celery(
    "worker",
    broker="pyamqp://guest@localhost//",
    backend="rpc://"
)

def get_db_conn_and_cursor():
    conn = get_db_connection()
    return conn, conn.cursor()

def close_db_conn_and_cursor(conn, cursor):
    if cursor:
        cursor.close()
    if conn:
        conn.close()

# Dynamically import all tasks to ensure they are registered.
def register_tasks():
    tasks_dir = os.path.join(os.path.dirname(__file__), "src", "tasks")
    for filename in os.listdir(tasks_dir):
        if filename.endswith(".py") and not filename.startswith("__"):
            module_name = f"src.tasks.{filename[:-3]}"
            importlib.import_module(module_name)

register_tasks()

@app.task(bind=True, max_retries=3, default_retry_delay=5)
def process_image(self, task_name: str, image_id: str, job_item_id: str):
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
