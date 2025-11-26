"""This module initializes the task registry and provides a decorator for registering tasks."""

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
