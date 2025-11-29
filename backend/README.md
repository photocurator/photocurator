# PhotoCurator Backend

This directory contains the Node.js backend for the PhotoCurator application. It is built using the [Hono](https://hono.dev/) web framework and [Drizzle ORM](https://orm.drizzle.team/) for database access.

## Features

*   **Project Management**: Create and manage photo projects.
*   **Image Upload and Management**: Upload images to projects and manage their metadata.
*   **AI Analysis Pipeline**: Trigger and monitor AI analysis jobs for images.
*   **User Feedback**: Record user feedback on images, such as picks, rejections, and ratings.
*   **Targeted Advertising**: Serve targeted ads to users based on their shooting patterns.
*   **User Statistics**: Track and retrieve user shooting statistics.

## API Documentation

The API is documented using OpenAPI and can be accessed via Swagger UI. Once the server is running, you can view the documentation at [http://localhost:3000/api/ui](http://localhost:3000/api/ui).

## Getting Started

### Prerequisites

*   [Bun](https://bun.sh/)

### Installation

To install dependencies, run the following command:

```sh
bun install
```

### Running the Server

To start the development server, run:

```sh
bun run dev
```

The server will be available at [http://localhost:3000](http://localhost:3000).
