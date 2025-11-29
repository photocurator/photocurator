"""This module defines the Celery task for assessing image quality."""
import pyiqa
import torch
from PIL import Image
import os
import uuid
from ..db import get_db_connection
from . import register_task, unload_other_models
from .base import ImageProcessingTask

@register_task("quality_assessment")
class QualityAssessmentTask(ImageProcessingTask):
    """A Celery task to assess the quality of an image using the TOPIQ model.
    """
    model = None

    def _load_model(self):
        """Lazily loads the TOPIQ image quality assessment model."""
        unload_other_models(QualityAssessmentTask)
        use_gpu = os.getenv("USE_GPU", "true").lower() == "true"
        device = torch.device('cuda' if use_gpu and torch.cuda.is_available() else 'cpu')
        if QualityAssessmentTask.model is None:
            QualityAssessmentTask.model = pyiqa.create_metric('topiq_nr', device=device)
        else:
            QualityAssessmentTask.model.to(device)

    def run(self, image_id: str):
        """The main execution method for the task.

        This method retrieves the image path from the database, assesses its quality using the TOPIQ model,
        and then stores the quality score back into the database.

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
                return

            image_path = image_path_tuple[0]

            storage_base_path = os.getenv("STORAGE_BASE_PATH", "/home/p4b/Documents/photocurator/backend")
            full_image_path = os.path.join(storage_base_path, image_path)

            score = self.model(full_image_path).item()

            # The 'quality_score' table has a 'musiq_score' column. Storing the 'topiq'
            # score in this column as per the existing schema.
            cur.execute(
                """
                INSERT INTO quality_score (id, image_id, musiq_score, model_version, created_at, updated_at)
                VALUES (%s, %s, %s, %s, NOW(), NOW())
                ON CONFLICT (image_id) DO UPDATE SET
                    musiq_score = EXCLUDED.musiq_score,
                    model_version = EXCLUDED.model_version,
                    updated_at = NOW();
                """,
                (str(uuid.uuid4()), image_id, score, "topiq_nr")
            )

            conn.commit()
        finally:
            if cur:
                cur.close()
            if conn:
                conn.close()
