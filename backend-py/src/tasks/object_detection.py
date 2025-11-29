"""This module defines the Celery task for detecting objects in images."""
import torch
from ultralytics import YOLO
from PIL import Image
import os
from ..db import get_db_connection
from . import register_task, unload_other_models
from .base import ImageProcessingTask
import uuid

@register_task("object_detection")
class ObjectDetectionTask(ImageProcessingTask):
    """A Celery task to detect objects in an image using a YOLO model.
    """
    model = None

    def _load_model(self):
        """Lazily loads the YOLO object detection model."""
        unload_other_models(ObjectDetectionTask)
        if ObjectDetectionTask.model is None:
            # Using yolov10x as yolov12x is not a recognized model.
            ObjectDetectionTask.model = YOLO("yolov10x.pt")

    def run(self, image_id: str):
        """The main execution method for the task.

        This method retrieves the image path from the database, runs object detection using the YOLO model,
        and then stores the detected object tags and their bounding boxes back into the database.

        Args:
            image_id (str): The ID of the image to be processed.
        """
        self._load_model()

        conn = None
        cur = None
        try:
            conn = get_db_connection()
            cur = conn.cursor()

            cur.execute("SELECT storage_path FROM image WHERE id = %s", (image_id,))
            image_path_tuple = cur.fetchone()
            if not image_path_tuple:
                # Handle case where image_id is not found
                return

            image_path = image_path_tuple[0]

            storage_base_path = os.getenv("STORAGE_BASE_PATH", "/storage")
            full_image_path = os.path.join(storage_base_path, image_path)
            
            use_gpu = os.getenv("USE_GPU", "true").lower() == "true"
            device = 0 if use_gpu and torch.cuda.is_available() else 'cpu'
            results = self.model(full_image_path, device=device)

            for result in results:
                for box in result.boxes:
                    tag_name = self.model.names[int(box.cls)]
                    confidence = float(box.conf)
                    x1, y1, x2, y2 = box.xyxy[0]
                    bounding_box_x = int(x1)
                    bounding_box_y = int(y1)
                    bounding_box_width = int(x2 - x1)
                    bounding_box_height = int(y2 - y1)

                    cur.execute(
                        """
                        INSERT INTO object_tag (id, image_id, tag_name, confidence,
                                                bounding_box_x, bounding_box_y,
                                                bounding_box_width, bounding_box_height,
                                                model_version, created_at, updated_at)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                        """,
                        (str(uuid.uuid4()), image_id, tag_name, confidence,
                         bounding_box_x, bounding_box_y,
                         bounding_box_width, bounding_box_height,
                         "yolov10x")
                    )

            conn.commit()
        finally:
            if cur:
                cur.close()
            if conn:
                conn.close()
