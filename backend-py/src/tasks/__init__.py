"""This module initializes the task registry and provides a decorator for registering tasks."""
import gc
import torch
import os

TASK_REGISTRY = {}

def register_task(name):
    """A decorator to register a task class in the TASK_REGISTRY.

    Args:
        name (str): The name to register the task with.

    Returns:
        function: The decorator function.
    """
    def decorator(cls):
        """The actual decorator that registers the class.

        Args:
            cls (class): The class to register.

        Returns:
            class: The registered class.
        """
        TASK_REGISTRY[name] = cls
        return cls
    return decorator

def unload_other_models(current_task_class):
    """Offloads models from all other registered tasks to CPU to free up GPU memory.

    Args:
        current_task_class (class): The class of the task currently attempting to run.
    """
    for name, task_cls in TASK_REGISTRY.items():
        if task_cls != current_task_class:
            if hasattr(task_cls, 'model') and task_cls.model is not None:
                print(f"Offloading model for task: {name} to CPU")
                if hasattr(task_cls.model, 'cpu'):
                    task_cls.model.cpu()
                elif hasattr(task_cls.model, 'to'):
                    task_cls.model.to('cpu')
                # For Ultralytics YOLO, checking internal model
                elif hasattr(task_cls.model, 'model') and hasattr(task_cls.model.model, 'cpu'):
                    task_cls.model.model.cpu()

    gc.collect()
    use_gpu = os.getenv("USE_GPU", "true").lower() == "true"
    if use_gpu and torch.cuda.is_available():
        torch.cuda.empty_cache()
