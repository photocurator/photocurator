# PhotoCurator Python Backend

This directory contains the Python backend for the PhotoCurator application. It is responsible for handling asynchronous, computationally intensive tasks using [Celery](https://docs.celeryq.dev/en/stable/) and [FastAPI](https://fastapi.tiangolo.com/).

## Features

*   **Image Analysis**: Performs various AI-powered analyses on images, including:
    *   **EXIF and GPS Extraction**: Extracts metadata from images.
    *   **Image Captioning**: Generates detailed captions for images.
    *   **Object Detection**: Detects objects within images and their bounding boxes.
    *   **Quality Assessment**: Assesses the quality of images using various metrics.
*   **Task Queueing**: Uses Celery to manage a queue of analysis tasks, allowing for scalable and reliable processing.
*   **API for Task Management**: Provides a FastAPI endpoint for enqueuing new tasks and checking their status.

## Getting Started

### Prerequisites

*   [Python 3.10+](https://www.python.org/)
*   [Poetry](https://python-poetry.org/)
*   [Redis](https://redis.io/) (for Celery broker and backend)

### Installation

To install dependencies, run the following command:

```sh
poetry install
```

### Running the Services

To run the Python backend, you will need to start two services: the FastAPI server and the Celery worker.

**1. Start the FastAPI Server:**

```sh
poetry run uvicorn server:app --reload
```

The server will be available at [http://localhost:8000](http://localhost:8000).

**2. Start the Celery Worker:**

```sh
poetry run celery -A worker.app worker --loglevel=info
```

This will start a Celery worker that will begin processing tasks from the queue.
