import uuid
from collections import Counter
from .db import get_db_connection, release_db_connection

def calculate_user_statistics(user_id: str):
    """Calculates shooting statistics for a user and updates the database.

    Args:
        user_id (str): The ID of the user.
    """
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # 1. Fetch all EXIF data for the user's images
        cur.execute(
            """
            SELECT 
                e.camera_make,
                e.camera_model,
                e.lens_model,
                e.focal_length_mm,
                e.aperture_f,
                e.iso
            FROM image i
            JOIN image_exif e ON i.id = e.image_id
            WHERE i.user_id = %s
            """,
            (user_id,)
        )
        rows = cur.fetchall()

        # Check if stats exist
        cur.execute("SELECT id FROM shooting_pattern WHERE user_id = %s", (user_id,))
        existing_row = cur.fetchone()
        existing_id = existing_row[0] if existing_row else None

        if not rows:
            # No photos or no EXIF data
            if existing_id:
                cur.execute(
                    """
                    UPDATE shooting_pattern SET
                        total_photos_analyzed = 0,
                        last_analyzed_at = NOW()
                    WHERE id = %s
                    """,
                    (existing_id,)
                )
            else:
                cur.execute(
                    """
                    INSERT INTO shooting_pattern (id, user_id, total_photos_analyzed, last_analyzed_at, created_at)
                    VALUES (%s, %s, 0, NOW(), NOW())
                    """,
                    (str(uuid.uuid4()), user_id)
                )
            conn.commit()
            return

        total_photos = len(rows)
        
        camera_counts = Counter()
        lens_counts = Counter()
        focal_length_counts = Counter()
        aperture_counts = Counter()
        iso_sum = 0
        iso_count = 0

        for row in rows:
            camera_make, camera_model, lens_model, focal_length, aperture, iso = row
            
            # Camera
            if camera_make and camera_model:
                camera_counts[f"{camera_make} {camera_model}"] += 1
            elif camera_model:
                camera_counts[camera_model] += 1
            
            # Lens
            if lens_model:
                lens_counts[lens_model] += 1
            
            # Focal Length
            if focal_length is not None:
                 focal_length_counts[float(focal_length)] += 1

            # Aperture
            if aperture is not None:
                aperture_counts[float(aperture)] += 1
            
            # ISO
            if iso is not None:
                iso_sum += iso
                iso_count += 1

        most_used_camera = camera_counts.most_common(1)[0][0] if camera_counts else None
        most_used_lens = lens_counts.most_common(1)[0][0] if lens_counts else None
        most_common_focal_length = focal_length_counts.most_common(1)[0][0] if focal_length_counts else None
        most_common_aperture = aperture_counts.most_common(1)[0][0] if aperture_counts else None
        avg_iso = (iso_sum / iso_count) if iso_count > 0 else None

        # Update database
        if existing_id:
            cur.execute(
                """
                UPDATE shooting_pattern SET
                    most_used_camera_id = %s,
                    most_used_lens_id = %s,
                    avg_iso = %s,
                    most_common_aperture = %s,
                    most_common_focal_length = %s,
                    total_photos_analyzed = %s,
                    last_analyzed_at = NOW()
                WHERE id = %s
                """,
                (
                    most_used_camera, most_used_lens,
                    avg_iso, most_common_aperture, most_common_focal_length,
                    total_photos, existing_id
                )
            )
        else:
            cur.execute(
                """
                INSERT INTO shooting_pattern (
                    id, user_id, most_used_camera_id, most_used_lens_id, 
                    avg_iso, most_common_aperture, most_common_focal_length, 
                    total_photos_analyzed, last_analyzed_at, created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """,
                (
                    str(uuid.uuid4()), user_id, most_used_camera, most_used_lens,
                    avg_iso, most_common_aperture, most_common_focal_length,
                    total_photos
                )
            )
        conn.commit()

    except Exception as e:
        print(f"Error calculating statistics for user {user_id}: {e}")
        if conn:
            conn.rollback()
    finally:
        if cur:
            cur.close()
        if conn:
            release_db_connection(conn)
