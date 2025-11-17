from fastapi import FastAPI
from pydantic import BaseModel
from celery.result import AsyncResult
from worker import process_image
from src.db import get_db_connection
import uuid

app = FastAPI()

class TaskRequest(BaseModel):
    image_id: str
    task_name: str
    project_id: str
    user_id: str

class TaskStatus(BaseModel):
    task_id: str
    status: str
    result: dict | None = None

@app.post("/tasks/", response_model=TaskStatus)
def enqueue_task(task_request: TaskRequest):
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        job_id = str(uuid.uuid4())
        cur.execute(
            """
            INSERT INTO analysis_job (id, project_id, user_id, job_type, created_at, updated_at)
            VALUES (%s, %s, %s, %s, NOW(), NOW())
            """,
            (job_id, task_request.project_id, task_request.user_id, task_request.task_name)
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
    task_result = AsyncResult(task_id)
    result = task_result.result if task_result.ready() else None
    return TaskStatus(task_id=task_id, status=task_result.status, result=result)
