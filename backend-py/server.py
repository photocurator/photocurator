"""This module defines the FastAPI server for enqueuing and monitoring Celery tasks."""
from fastapi import FastAPI
from pydantic import BaseModel
from celery.result import AsyncResult
from worker import process_image
from src.db import get_db_connection
import uuid

app = FastAPI()

class TaskRequest(BaseModel):
    """Request model for enqueuing a new image processing task."""
    image_id: str
    task_name: str
    project_id: str
    user_id: str

class AnalyzeRequestItem(BaseModel):
    image_id: str
    task_name: str
    job_item_id: str

class BatchAnalyzeRequest(BaseModel):
    requests: list[AnalyzeRequestItem]

class TaskStatus(BaseModel):
    """Response model for the status of a Celery task."""
    task_id: str
    status: str
    result: dict | None = None

@app.post("/batch-analyze")
def batch_analyze(batch_request: BatchAnalyzeRequest):
    """Enqueues a batch of image processing tasks.

    This endpoint receives a list of tasks (already recorded in the DB by the main backend)
    and enqueues them to the Celery worker.

    Args:
        batch_request (BatchAnalyzeRequest): The request body containing the list of tasks.

    Returns:
        dict: A message indicating the number of tasks enqueued.
    """
    for item in batch_request.requests:
        process_image.delay(item.task_name, item.image_id, item.job_item_id)
    return {"message": "Batch analysis started", "count": len(batch_request.requests)}

@app.post("/tasks/", response_model=TaskStatus)
def enqueue_task(task_request: TaskRequest):
    """Enqueues a new image processing task.

    This endpoint creates a new analysis job and a corresponding job item in the database,
    then enqueues a Celery task to process the image.

    Args:
        task_request (TaskRequest): The request body containing the image ID, task name, project ID, and user ID.

    Returns:
        TaskStatus: The initial status of the enqueued task.
    """
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        job_id = str(uuid.uuid4())
        cur.execute(
            """
            INSERT INTO analysis_job (id, project_id, user_id, job_type, job_status, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
            """,
            (job_id, task_request.project_id, task_request.user_id, task_request.task_name, "pending")
        )

        job_item_id = str(uuid.uuid4())
        cur.execute(
            """
            INSERT INTO analysis_job_item (id, job_id, image_id, created_at)
            VALUES (%s, %s, %s, NOW())
            """,
            (job_item_id, job_id, task_request.image_id)
        )

        conn.commit()

        task = process_image.delay(task_request.task_name, task_request.image_id, job_item_id)
        return TaskStatus(task_id=task.id, status="PENDING")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

@app.get("/tasks/{task_id}", response_model=TaskStatus)
def get_task_status(task_id: str):
    """Retrieves the status of a Celery task.

    Args:
        task_id (str): The ID of the task to retrieve the status for.

    Returns:
        TaskStatus: The current status of the task, including the result if the task is complete.
    """
    task_result = AsyncResult(task_id)
    result = task_result.result if task_result.ready() else None
    return TaskStatus(task_id=task_id, status=task_result.status, result=result)
