"""This module defines the Celery task for generating image captions."""
from transformers import AutoProcessor, AutoModelForCausalLM
from PIL import Image
import os
import uuid
from ..db import get_db_connection, release_db_connection
from . import register_task, unload_other_models
from .base import ImageProcessingTask
import torch

@register_task("image_captioning")
class ImageCaptioningTask(ImageProcessingTask):
    """A Celery task to generate a detailed caption for an image using a pre-trained model.
    """
    model = None
    processor = None

    @property
    def version(self):
        return "Florence-2-base-ft"

    def check_already_processed(self, cur, image_id: str) -> bool:
        cur.execute(
            "SELECT 1 FROM image_caption WHERE image_id = %s AND model_version = %s",
            (image_id, self.version)
        )
        return cur.fetchone() is not None

    def _load_model(self):
        """Lazily loads the pre-trained image captioning model and processor."""
        unload_other_models(ImageCaptioningTask)
        use_gpu = os.getenv("USE_GPU", "true").lower() == "true"
        device = "cuda" if use_gpu and torch.cuda.is_available() else "cpu"
        if ImageCaptioningTask.model is None:
            # Force CPU for now due to potential issues with Florence on some GPU setups or fallbacks
            # Or stick to dynamic device but be careful with inputs.
            # The error '_supports_sdpa' often relates to transformer version or model config mismatch.
            # Disabling sdpa via loading option if possible or just catch.
            # For Florence-2-base-ft, trust_remote_code=True is needed.
            
            # Attempt to fix AttributeError: 'Florence2ForConditionalGeneration' object has no attribute '_supports_sdpa'
            # This is often an issue with transformers version > 4.36 interacting with this model code.
            # We are using transformers>=4.43.3.
            # Explicitly setting it to False on the class or instance can help.
            
            ImageCaptioningTask.model = AutoModelForCausalLM.from_pretrained(
                "microsoft/Florence-2-base-ft", 
                trust_remote_code=True
            ).to(device)
            
            # Monkey patch on the instance
            if not hasattr(ImageCaptioningTask.model, '_supports_sdpa'):
                 object.__setattr__(ImageCaptioningTask.model, '_supports_sdpa', False) 

            ImageCaptioningTask.processor = AutoProcessor.from_pretrained("microsoft/Florence-2-base-ft", trust_remote_code=True)
        else:
            ImageCaptioningTask.model.to(device)

    def run(self, image_id: str):
        """The main execution method for the task.
        
        This method retrieves the image path from the database, generates a caption using the model,
        and then stores the caption back into the database.

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

            storage_base_path = os.getenv("STORAGE_BASE_PATH", "/storage")
            full_image_path = os.path.join(storage_base_path, image_path)

            image = Image.open(full_image_path)
            
            use_gpu = os.getenv("USE_GPU", "true").lower() == "true"
            device = "cuda" if use_gpu and torch.cuda.is_available() else "cpu"
            prompt = "<MORE_DETAILED_CAPTION>"
            inputs = self.processor(text=prompt, images=image, return_tensors="pt").to(device)

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
                INSERT INTO image_caption (id, image_id, caption, model_version, created_at, updated_at)
                VALUES (%s, %s, %s, %s, NOW(), NOW())
                """,
                (str(uuid.uuid4()), image_id, caption.strip(), "Florence-2-base-ft")
            )

            conn.commit()
        finally:
            if cur:
                cur.close()
            if conn:
                release_db_connection(conn)
