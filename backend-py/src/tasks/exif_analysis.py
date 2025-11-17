from PIL import Image
from PIL.ExifTags import TAGS, GPSTAGS
import os
import uuid
from ..db import get_db_connection
from . import register_task
from .base import ImageProcessingTask

@register_task("exif_analysis")
class ExifAnalysisTask(ImageProcessingTask):

    def _get_exif_data(self, image_path):
        """Extracts EXIF data from an image."""
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
                    gps_info[decode] = decoded_exif['GPSInfo'][key]

            return decoded_exif, gps_info
        except Exception:
            return None, None

    def _convert_dms_to_dd(self, dms, ref):
        """Converts DMS (Degrees, Minutes, Seconds) to DD (Decimal Degrees)."""
        degrees = dms[0]
        minutes = dms[1] / 60.0
        seconds = dms[2] / 3600.0

        dd = degrees + minutes + seconds
        if ref in ['S', 'W']:
            dd *= -1
        return dd

    def run(self, image_id: str):
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

            exif_data, gps_info = self._get_exif_data(full_image_path)

            if exif_data:
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
                    str(exif_data.get('ExposureTime')), exif_data.get('ISOSpeedRatings')
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
            if conn:
                cur.close()
                conn.close()
