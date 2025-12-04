"""This module defines the Celery task for grouping similar images."""
import os
import uuid
from datetime import timedelta
from PIL import Image
import imagehash
from ..db import get_db_connection, release_db_connection
from . import register_task
from .base import ImageProcessingTask

@register_task("similarity_grouping")
class SimilarityGroupingTask(ImageProcessingTask):
    @property
    def version(self):
        return "1.0.0"


    def run(self, image_id: str):
        """The main execution method for the task.

        Args:
            image_id (str): The ID of the image to be processed.
        """
        conn = None
        cur = None
        try:
            conn = get_db_connection()
            cur = conn.cursor()

            # 1. Fetch image details
            cur.execute(
                "SELECT storage_path, project_id, capture_datetime, perceptual_hash, upload_datetime FROM image WHERE id = %s",
                (image_id,)
            )
            row = cur.fetchone()
            if not row:
                return

            storage_path, project_id, capture_datetime, existing_hash, upload_datetime = row
            
            # 2. Calculate Hash if not exists
            p_hash_obj = None
            p_hash_str = existing_hash

            if not p_hash_str:
                storage_base_path = os.getenv("STORAGE_BASE_PATH", "/storage")
                full_image_path = os.path.join(storage_base_path, storage_path)
                try:
                    img = Image.open(full_image_path)
                    p_hash_obj = imagehash.phash(img)
                    p_hash_str = str(p_hash_obj)
                    
                    # Update DB
                    cur.execute(
                        "UPDATE image SET perceptual_hash = %s, updated_at = NOW() WHERE id = %s",
                        (p_hash_str, image_id)
                    )
                    conn.commit()
                except Exception as e:
                    print(f"Failed to calculate hash for {image_id}: {e}")
                    return
            else:
                p_hash_obj = imagehash.hex_to_hash(p_hash_str)

            reference_time = capture_datetime if capture_datetime else upload_datetime

            if not reference_time:
                # Should not happen as upload_datetime is not null, but safety check
                print(f"Image {image_id} has no capture_datetime or upload_datetime. Skipping similarity grouping.")
                return

            # 3. Find candidates in time window
            # Window is +/- 5 minutes
            time_window = timedelta(minutes=5)
            start_time = reference_time - time_window
            end_time = reference_time + time_window

            cur.execute(
                """
                SELECT id, perceptual_hash 
                FROM image 
                WHERE project_id = %s 
                  AND id != %s 
                  AND COALESCE(capture_datetime, upload_datetime) BETWEEN %s AND %s
                  AND perceptual_hash IS NOT NULL
                """,
                (project_id, image_id, start_time, end_time)
            )
            candidates = cur.fetchall()

            threshold = 10 # Hamming distance threshold
            matching_image_ids = []

            for cand_id, cand_hash_str in candidates:
                cand_hash_obj = imagehash.hex_to_hash(cand_hash_str)
                if p_hash_obj - cand_hash_obj <= threshold:
                    matching_image_ids.append(cand_id)

            if not matching_image_ids:
                return

            # 4. Check for existing groups
            # We look for any existing 'similar' group that contains one of the matching images
            placeholders = ','.join(['%s'] * len(matching_image_ids))
            query = f"""
                SELECT DISTINCT ig.id 
                FROM image_group ig
                JOIN image_group_membership igm ON ig.id = igm.group_id
                WHERE ig.group_type = 'similar'
                  AND igm.image_id IN ({placeholders})
            """
            cur.execute(query, tuple(matching_image_ids))
            existing_groups = cur.fetchall()

            group_id = None

            if existing_groups:
                # Join the first found group (simple logic)
                group_id = existing_groups[0][0]
            else:
                # Create new group
                group_id = str(uuid.uuid4())
                cur.execute(
                    """
                    INSERT INTO image_group (id, project_id, group_type, created_at, updated_at)
                    VALUES (%s, %s, 'similar', NOW(), NOW())
                    """,
                    (group_id, project_id)
                )
                
                # Add the matching image(s) to this new group
                # Note: If we matched multiple images that weren't in groups, we add them all?
                # Or just the one we matched? Logic: If A matches B and C, and B, C are not in groups.
                # We create group with A, B, C.
                for match_id in matching_image_ids:
                    # Check if already in group to be safe
                    cur.execute(
                        "SELECT 1 FROM image_group_membership WHERE group_id = %s AND image_id = %s",
                        (group_id, match_id)
                    )
                    if not cur.fetchone():
                        cur.execute(
                            """
                            INSERT INTO image_group_membership (id, group_id, image_id, added_at)
                            VALUES (%s, %s, %s, NOW())
                            """,
                            (str(uuid.uuid4()), group_id, match_id)
                        )

            # Add current image to the group
            cur.execute(
                "SELECT 1 FROM image_group_membership WHERE group_id = %s AND image_id = %s",
                (group_id, image_id)
            )
            if not cur.fetchone():
                cur.execute(
                    """
                    INSERT INTO image_group_membership (id, group_id, image_id, added_at)
                    VALUES (%s, %s, %s, NOW())
                    """,
                    (str(uuid.uuid4()), group_id, image_id)
                )

            conn.commit()

        finally:
            if cur:
                cur.close()
            if conn:
                release_db_connection(conn)

