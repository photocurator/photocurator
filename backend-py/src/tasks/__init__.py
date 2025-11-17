TASK_REGISTRY = {}

def register_task(name):
    def decorator(cls):
        TASK_REGISTRY[name] = cls
        return cls
    return decorator
