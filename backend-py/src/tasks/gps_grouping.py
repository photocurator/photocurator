"""This module defines the Celery task for grouping images based on GPS location."""
import math
import uuid
from ..db import get_db_connection, release_db_connection
from . import register_task
from .base import ImageProcessingTask

@register_task("gps_grouping")
class GpsGroupingTask(ImageProcessingTask):
    @property
    def version(self):
        return "1.0.0"

    def check_already_processed(self, cur, image_id: str) -> bool:
        cur.execute(
            """
            SELECT 1 
            FROM image_group_membership igm
            JOIN image_group ig ON igm.group_id = ig.id
            WHERE igm.image_id = %s AND ig.group_type = 'gps'
            """,
            (image_id,)
        )
        return cur.fetchone() is not None

    def _haversine_distance(self, lat1, lon1, lat2, lon2):
        """Calculates the Haversine distance between two points in meters.

        Args:
            lat1 (float): Latitude of point 1.
            lon1 (float): Longitude of point 1.
            lat2 (float): Latitude of point 2.
            lon2 (float): Longitude of point 2.

        Returns:
            float: Distance in meters.
        """
        R = 6371000  # Radius of Earth in meters
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = math.sin(delta_phi / 2)**2 + \
            math.cos(phi1) * math.cos(phi2) * \
            math.sin(delta_lambda / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c

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

            # 1. Fetch current image GPS and project ID
            cur.execute(
                """
                SELECT i.project_id, g.latitude, g.longitude
                FROM image i
                JOIN image_gps g ON i.id = g.image_id
                WHERE i.id = %s
                """,
                (image_id,)
            )
            row = cur.fetchone()
            if not row:
                # No GPS data or image not found
                return

            project_id, lat1, lon1 = row
            lat1, lon1 = float(lat1), float(lon1)

            # 2. Find other images in the same project with GPS data
            # Use a conservative bounding box (SQL).
            # 0.1 degrees covers > 11km at equator, and even at 89 deg latitude (cos(89) ~ 0.017),
            # 0.1 deg longitude is ~11km * 0.017 = ~190m. So 0.1 deg is safe globally for 100m radius.
            lat_delta = 0.1
            lon_delta = 0.1

            cur.execute(
                """
                SELECT i.id, g.latitude, g.longitude
                FROM image i
                JOIN image_gps g ON i.id = g.image_id
                WHERE i.project_id = %s
                  AND i.id != %s
                  AND g.latitude BETWEEN %s AND %s
                  AND g.longitude BETWEEN %s AND %s
                """,
                (project_id, image_id, lat1 - lat_delta, lat1 + lat_delta, lon1 - lon_delta, lon1 + lon_delta)
            )
            candidates = cur.fetchall()

            matching_image_ids = []
            max_distance = 100.0  # meters

            for cand_id, lat2, lon2 in candidates:
                dist = self._haversine_distance(lat1, lon1, float(lat2), float(lon2))
                if dist <= max_distance:
                    matching_image_ids.append(cand_id)

            if not matching_image_ids:
                # Even if no matches, we might want to check if the current image is already in a 'gps' group
                # If it is, and we found no neighbors, it means it's alone in that group (or others moved away?).
                # But requirement is just grouping. If alone, maybe fine.
                # However, to be consistent, we might leave it alone or create a group for itself if we want
                # strictly "every image with GPS has a GPS group".
                # For now, following similarity logic: return if no matches.
                return

            # 3. Handle Grouping (Merge Logic)

            # Find all unique groups that currently contain ANY of the matching images OR the current image
            all_involved_ids = matching_image_ids + [image_id]
            placeholders = ','.join(['%s'] * len(all_involved_ids))
            query = f"""
                SELECT DISTINCT ig.id
                FROM image_group ig
                JOIN image_group_membership igm ON ig.id = igm.group_id
                WHERE ig.group_type = 'gps'
                  AND igm.image_id IN ({placeholders})
            """
            cur.execute(query, tuple(all_involved_ids))
            existing_group_rows = cur.fetchall()
            existing_group_ids = [row[0] for row in existing_group_rows]

            target_group_id = None

            if not existing_group_ids:
                # Create a completely new group
                target_group_id = str(uuid.uuid4())
                cur.execute(
                    """
                    INSERT INTO image_group (id, project_id, group_type, created_at, updated_at)
                    VALUES (%s, %s, 'gps', NOW(), NOW())
                    """,
                    (target_group_id, project_id)
                )
            else:
                # Use the first group as the "survivor"
                target_group_id = existing_group_ids[0]

                # If there are multiple groups, merge them
                if len(existing_group_ids) > 1:
                    victim_group_ids = existing_group_ids[1:]
                    victim_placeholders = ','.join(['%s'] * len(victim_group_ids))

                    # 1. Get all images from victim groups
                    cur.execute(f"""
                        SELECT image_id FROM image_group_membership WHERE group_id IN ({victim_placeholders})
                    """, tuple(victim_group_ids))
                    victim_members = [r[0] for r in cur.fetchall()]

                    # 2. Delete memberships of victim groups
                    cur.execute(f"""
                        DELETE FROM image_group_membership WHERE group_id IN ({victim_placeholders})
                    """, tuple(victim_group_ids))

                    # 3. Delete victim groups
                    cur.execute(f"""
                        DELETE FROM image_group WHERE id IN ({victim_placeholders})
                    """, tuple(victim_group_ids))

                    # 4. Add victim members to the list of IDs to be inserted/verified in target
                    all_involved_ids.extend(victim_members)

            # Insert/Ensure membership for all involved images
            # Use set to remove duplicates
            final_members = set(all_involved_ids)

            for member_id in final_members:
                # Check if membership already exists
                cur.execute(
                    "SELECT 1 FROM image_group_membership WHERE group_id = %s AND image_id = %s",
                    (target_group_id, member_id)
                )
                if not cur.fetchone():
                    cur.execute(
                        """
                        INSERT INTO image_group_membership (id, group_id, image_id, added_at)
                        VALUES (%s, %s, %s, NOW())
                        """,
                        (str(uuid.uuid4()), target_group_id, member_id)
                    )

            conn.commit()

        finally:
            if cur:
                cur.close()
            if conn:
                release_db_connection(conn)
