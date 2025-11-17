from transformers import AutoProcessor, AutoModelForCausalLM
from PIL import Image
import os
import uuid
from ..db import get_db_connection
from . import register_task
from .base import ImageProcessingTask

@register_task("image_captioning")
class ImageCaptioningTask(ImageProcessingTask):
    model = None
    processor = None

    def _load_model(self):
        if self.model is None:
            self.model = AutoModelForCausalLM.from_pretrained("microsoft/Florence-2-base-ft", trust_remote_code=True)
            self.processor = AutoProcessor.from_pretrained("microsoft/Florence-2-base-ft", trust_remote_code=True)

    def run(self, image_id: str):
        self._load_model()

        conn = None
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

            image = Image.open(full_image_path)

            prompt = "<MORE_DETAILED_CAPTION>"
            inputs = self.processor(text=prompt, images=image, return_tensors="pt")

            generated_ids = self.model.generate(
                input_ids=inputs["input_ids"],
                pixel_values=inputs["pixel_values"],
                max_new_tokens=1024,
                num_beams=3
            )

            generated_text = self.processor.batch_decode(generated_ids, skip_special_tokens=False)[0]

            # The generated text will be in the format of '<MORE_DETAILED_CAPTION>The caption text'.
            # We need to parse it to extract only the caption.
            caption = generated_text.split("</s>")[0].split(prompt)[-1]

            cur.execute(
                """
                INSERT INTO object_tag (id, image_id, tag_name, tag_category, model_version, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
                """,
                (str(uuid.uuid4()), image_id, caption.strip(), "caption", "Florence-2-base-ft")
            )

            conn.commit()
        finally:
            if conn:
                cur.close()
                conn.close()
