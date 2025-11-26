"""This module defines the abstract base class for all image processing tasks."""
from abc import ABC, abstractmethod

class ImageProcessingTask(ABC):
    """Abstract base class for image processing tasks.

    All specific image processing tasks should inherit from this class
    and implement the `run` method.
    """

    @abstractmethod
    def run(self, image_id: str):
        """The main execution method for the task.

        Args:
            image_id (str): The ID of the image to be processed.
        """
        pass
