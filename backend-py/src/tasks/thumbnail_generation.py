"""This module defines the Celery task for generating thumbnails for images."""
from PIL import Image, ImageOps
import os
from ..db import get_db_connection, release_db_connection
from . import register_task
from .base import ImageProcessingTask

@register_task("thumbnail_generation")
class ThumbnailGenerationTask(ImageProcessingTask):
    @property
    def version(self):
        return "1.0.0"

    def check_already_processed(self, cur, image_id: str) -> bool:
        cur.execute(
            "SELECT thumbnail_path FROM image WHERE id = %s",
            (image_id,)
        )
        row = cur.fetchone()
        return row and row[0] is not None

    def run(self, image_id: str):
        """The main execution method for the task.

        This method retrieves the image path from the database, generates a thumbnail,
        saves it to disk, and updates the database with the thumbnail path.

        Args:
            image_id (str): The ID of the image to be processed.
        """
        print(f"Generating thumbnail for {image_id}")
        conn = None
        cur = None
        try:
            conn = get_db_connection()
            cur = conn.cursor()

            cur.execute("SELECT storage_path, project_id FROM image WHERE id = %s", (image_id,))
            image_path_tuple = cur.fetchone()
            if not image_path_tuple:
                return

            original_image_path = image_path_tuple[0]
            project_id = image_path_tuple[1]
            
            storage_base_path = os.getenv("STORAGE_BASE_PATH", ".") # Default to current dir if not set (for local dev)
            
            # Handle potential absolute path in DB or relative
            if original_image_path.startswith("/"):
                full_original_path = original_image_path
            else:
                full_original_path = os.path.join(storage_base_path, original_image_path)

            if not os.path.exists(full_original_path):
                print(f"Original image not found at {full_original_path}")
                return

            try:
                with Image.open(full_original_path) as img:
                    # Fix orientation based on EXIF
                    img = ImageOps.exif_transpose(img)
                    
                    # Convert to RGB if necessary (e.g. for RGBA -> JPEG/WebP)
                    if img.mode in ("RGBA", "P"):
                        img = img.convert("RGB")
                    
                    # Resize logic: Max width 256px, preserve aspect ratio
                    max_width = 256
                    width_percent = (max_width / float(img.size[0]))
                    if width_percent < 1: # Only scale down
                        h_size = int((float(img.size[1]) * float(width_percent)))
                        img = img.resize((max_width, h_size), Image.Resampling.LANCZOS)
                    
                    # Determine thumbnail path
                    # Original: storage/images/{projectId}/{imageId}.ext
                    # Thumbnail: storage/thumbnails/{projectId}/{imageId}.webp
                    
                    thumbnails_dir = os.path.join(storage_base_path, "storage", "thumbnails", project_id)
                    os.makedirs(thumbnails_dir, exist_ok=True)
                    
                    thumbnail_filename = f"{image_id}.webp"
                    thumbnail_full_path = os.path.join(thumbnails_dir, thumbnail_filename)
                    
                    # Save as WebP
                    img.save(thumbnail_full_path, "WEBP", quality=80)
                    
                    # DB path should match format of storage_path (relative to where app expects)
                    # if original is `storage/images/...`, thumbnail should be `storage/thumbnails/...`
                    db_thumbnail_path = f"storage/thumbnails/{project_id}/{thumbnail_filename}"
                    
                    cur.execute(
                        "UPDATE image SET thumbnail_path = %s WHERE id = %s",
                        (db_thumbnail_path, image_id)
                    )
                    
                    conn.commit()

            except Exception as e:
                print(f"Error generating thumbnail for {image_id}: {e}")
                return

        finally:
            if cur:
                cur.close()
            if conn:
                release_db_connection(conn)
