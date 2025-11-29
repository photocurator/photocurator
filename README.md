# PhotoCurator

PhotoCurator is a powerful and intelligent photo management application designed to help you organize, analyze, and curate your photos. It uses a combination of a Node.js backend for core application logic and a Python backend for AI-powered image analysis.

## Architecture

The PhotoCurator application is composed of two main backend services:

*   **Node.js Backend (`/backend`)**: This is the primary backend for the application, responsible for handling user authentication, project management, image uploads, and serving the API for the frontend. It is built with [Hono](https://hono.dev/) and [Drizzle ORM](https://orm.drizzle.team/). For more details, see the [`backend/README.md`](./backend/README.md).

*   **Python Backend (`/backend-py`)**: This backend is dedicated to running computationally intensive, AI-powered image analysis tasks. It uses [Celery](https://docs.celeryq.dev/en/stable/) for task queueing and [FastAPI](https://fastapi.tiangolo.com/) to expose an API for managing analysis tasks. For more details, see the [`backend-py/README.md`](./backend-py/README.md).

## Features

*   **Project-Based Photo Organization**: Group your photos into projects for easy management.
*   **AI-Powered Image Analysis**: Automatically analyze your images for:
    *   **EXIF and GPS data**
    *   **Detailed captions**
    *   **Object detection**
    *   **Quality assessment**
*   **Intelligent Curation**: Get recommendations for the best shots in a series.
*   **Advanced Search**: Search for images by caption, tags, and other metadata.
*   **Personalized Experience**: The application learns from your preferences to provide a more personalized experience.

## Getting Started

To get started with PhotoCurator, please refer to the README files in the individual backend directories for setup and usage instructions.
