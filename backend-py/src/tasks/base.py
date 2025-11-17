from abc import ABC, abstractmethod

class ImageProcessingTask(ABC):
    @abstractmethod
    def run(self, image_id: str):
        pass
