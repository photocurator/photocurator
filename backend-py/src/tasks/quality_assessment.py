import pyiqa
import torch
from PIL import Image
import os
import uuid
from ..db import get_db_connection
from . import register_task
from .base import ImageProcessingTask

@register_task("quality_assessment")
class QualityAssessmentTask(ImageProcessingTask):
    model = None

    def _load_model(self):
        if self.model is None:
            self.model = pyiqa.create_metric('topiq', device=torch.device('cpu'))

    def run(self, image_id: str):
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

            storage_base_path = os.getenv("STORAGE_BASE_PATH", "/storage")
            full_image_path = os.path.join(storage_base_path, image_path)

            score = self.model(full_image_path).item()

            # The 'quality_score' table has a 'musiq_score' column. Storing the 'topiq'
            # score in this column as per the existing schema.
            cur.execute(
                """
                INSERT INTO quality_score (id, image_id, musiq_score, model_version, created_at, updated_at)
                VALUES (%s, %s, %s, %s, NOW(), NOW())
                """,
                (str(uuid.uuid4()), image_id, score, "topiq_nr")
            )

            conn.commit()
        finally:
            if cur:
                cur.close()
            if conn:
                conn.close()
