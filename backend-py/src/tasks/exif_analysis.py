"""This module defines the Celery task for extracting EXIF and GPS data from images."""
from PIL import Image
from PIL.ExifTags import TAGS, GPSTAGS
import os
import uuid
from datetime import datetime
from ..db import get_db_connection, release_db_connection
from . import register_task
from .base import ImageProcessingTask

@register_task("exif_analysis")
class ExifAnalysisTask(ImageProcessingTask):
    @property
    def version(self):
        return "1.0.0"

    def check_already_processed(self, cur, image_id: str) -> bool:
        cur.execute(
            "SELECT 1 FROM image_exif WHERE image_id = %s",
            (image_id,)
        )
        return cur.fetchone() is not None

    def _get_exif_data(self, image_path):
        """Extracts EXIF and GPS data from an image file.

        Args:
            image_path (str): The path to the image file.

        Returns:
            tuple: A tuple containing the decoded EXIF data and GPS information,
                   or (None, None) if no EXIF data is found or an error occurs.
        """
        try:
            image = Image.open(image_path)
            exif_data = image._getexif()
            if not exif_data:
                return None, None

            decoded_exif = {TAGS.get(tag_id, tag_id): value for tag_id, value in exif_data.items()}
            gps_info = {}
            if 'GPSInfo' in decoded_exif:
                for key in decoded_exif['GPSInfo'].keys():
                    decode = GPSTAGS.get(key,key)
                    # Convert IFDRational to tuple or float if needed
                    val = decoded_exif['GPSInfo'][key]
                    if hasattr(val, 'numerator') and hasattr(val, 'denominator'):
                        val = float(val)
                    gps_info[decode] = val

            # Convert IFDRational values in main EXIF data as well
            for key, val in decoded_exif.items():
                 if hasattr(val, 'numerator') and hasattr(val, 'denominator'):
                     decoded_exif[key] = float(val)


            return decoded_exif, gps_info
        except Exception:
            return None, None

    def _convert_dms_to_dd(self, dms, ref):
        """Converts GPS coordinates from DMS (Degrees, Minutes, Seconds) to DD (Decimal Degrees).

        Args:
            dms (tuple): A tuple of degrees, minutes, and seconds.
            ref (str): The reference direction (e.g., 'N', 'S', 'E', 'W').

        Returns:
            float: The GPS coordinate in decimal degrees.
        """
        degrees = dms[0]
        minutes = dms[1] / 60.0
        seconds = dms[2] / 3600.0

        dd = degrees + minutes + seconds
        if ref in ['S', 'W']:
            dd *= -1
        return dd

    def _parse_exif_date(self, date_str):
        """Parses EXIF date string to datetime object.
        
        Args:
            date_str (str): Date string in format 'YYYY:MM:DD HH:MM:SS'
            
        Returns:
            datetime: Parsed datetime object or None if parsing fails
        """
        if not date_str:
            return None
        try:
            # Handle cases where the string might have null bytes or other garbage
            date_str = date_str.strip().replace('\x00', '')
            return datetime.strptime(date_str, '%Y:%m:%d %H:%M:%S')
        except (ValueError, TypeError):
            return None

    def run(self, image_id: str):
        """The main execution method for the task.

        This method retrieves the image path from the database, extracts EXIF and GPS data,
        and then stores the extracted data back into the database.

        Args:
            image_id (str): The ID of the image to be processed.
        """
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

            exif_data, gps_info = self._get_exif_data(full_image_path)

            if exif_data:
                # Extract capture time
                capture_time = None
                # Try different tags for date time
                for tag in ['DateTimeOriginal', 'DateTimeDigitized', 'DateTime']:
                    if tag in exif_data:
                        capture_time = self._parse_exif_date(exif_data[tag])
                        if capture_time:
                            break
                
                if capture_time:
                    cur.execute(
                        "UPDATE image SET capture_datetime = %s WHERE id = %s",
                        (capture_time, image_id)
                    )

                # Using INSERT ... ON CONFLICT to handle existing records
                cur.execute("""
                    INSERT INTO image_exif (id, image_id, camera_make, camera_model, lens_model, focal_length_mm, aperture_f, shutter_speed, iso, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
                    ON CONFLICT (image_id) DO UPDATE SET
                        camera_make = EXCLUDED.camera_make,
                        camera_model = EXCLUDED.camera_model,
                        lens_model = EXCLUDED.lens_model,
                        focal_length_mm = EXCLUDED.focal_length_mm,
                        aperture_f = EXCLUDED.aperture_f,
                        shutter_speed = EXCLUDED.shutter_speed,
                        iso = EXCLUDED.iso;
                """, (
                    str(uuid.uuid4()), image_id,
                    exif_data.get('Make'), exif_data.get('Model'), exif_data.get('LensModel'),
                    exif_data.get('FocalLength'), exif_data.get('FNumber'),
                    str(exif_data.get('ExposureTime')),
                    str(int(float(exif_data.get('ISOSpeedRatings')))) if exif_data.get('ISOSpeedRatings') else None
                ))

            if gps_info and 'GPSLatitude' in gps_info and 'GPSLongitude' in gps_info:
                lat = self._convert_dms_to_dd(gps_info['GPSLatitude'], gps_info.get('GPSLatitudeRef'))
                lon = self._convert_dms_to_dd(gps_info['GPSLongitude'], gps_info.get('GPSLongitudeRef'))
                alt = gps_info.get('GPSAltitude')

                cur.execute("""
                    INSERT INTO image_gps (id, image_id, latitude, longitude, altitude_m, created_at)
                    VALUES (%s, %s, %s, %s, %s, NOW())
                    ON CONFLICT (image_id) DO UPDATE SET
                        latitude = EXCLUDED.latitude,
                        longitude = EXCLUDED.longitude,
                        altitude_m = EXCLUDED.altitude_m;
                """, (str(uuid.uuid4()), image_id, lat, lon, alt))

            conn.commit()
        finally:
            if cur:
                cur.close()
            if conn:
                release_db_connection(conn)
