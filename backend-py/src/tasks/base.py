"""This module defines the abstract base class for all image processing tasks."""
from abc import ABC, abstractmethod

class ImageProcessingTask(ABC):
    """Abstract base class for image processing tasks.

    All specific image processing tasks should inherit from this class
    and implement the `run` method.
    """

    @property
    def version(self):
        """Returns the version of the task/model."""
        return "1.0.0"

    def check_already_processed(self, cur, image_id: str) -> bool:
        """Checks if the task has already been successfully processed for the given image and version.

        Args:
            cur (psycopg2.extensions.cursor): The database cursor.
            image_id (str): The ID of the image.

        Returns:
            bool: True if already processed, False otherwise.
        """
        return False

    @abstractmethod
    def run(self, image_id: str):
        """The main execution method for the task.

        Args:
            image_id (str): The ID of the image to be processed.
        """
        pass
