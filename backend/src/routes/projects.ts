/**
 * @module routes/projects
 * This file defines the API routes for managing projects, including creating projects,
 * retrieving project details, and handling image uploads and analysis within a project.
 */
import { OpenAPIHono, createRoute } from 'hono-zod-openapi';
import { z } from 'zod';
import { db } from '../db';
import { project, image, qualityScore, imageSelection, objectTag, analysisJob, analysisJobItem } from '../db/schema';
import { eq, and, gt, desc, inArray } from 'drizzle-orm';
import { mkdir, writeFile } from 'fs/promises';
import { v4 as uuidv4 } from 'uuid';
import { AuthType } from '../lib/auth';

type Variables = {
  user: AuthType['user'];
  session: AuthType['session'];
};

const app = new OpenAPIHono<{ Variables: Variables }>();

const ProjectSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  projectName: z.string(),
  description: z.string().nullable(),
  coverImageId: z.string().nullable(),
  isArchived: z.boolean(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
  archivedAt: z.string().datetime().nullable(),
});

const ImageSchema = z.object({
    id: z.string().uuid(),
    userId: z.string().uuid().nullable(),
    projectId: z.string().uuid(),
    originalFilename: z.string(),
    storagePath: z.string(),
    thumbnailPath: z.string().nullable(),
    fileSizeBytes: z.number(),
    mimeType: z.string(),
    widthPx: z.number().nullable(),
    heightPx: z.number().nullable(),
    compareViewSelected: z.boolean(),
    captureDatetime: z.string().datetime().nullable(),
    uploadDatetime: z.string().datetime(),
    createdAt: z.string().datetime(),
    updatedAt: z.string().datetime(),
  });

const QualityScoreSchema = z.object({
    id: z.string().uuid(),
    imageId: z.string().uuid(),
    brisqueScore: z.string().nullable(),
    tenegradScore: z.string().nullable(),
    musiqScore: z.string().nullable(),
    modelVersion: z.string(),
    updatedAt: z.string().datetime(),
    createdAt: z.string().datetime(),
    });

const ImageSelectionSchema = z.object({
    id: z.string().uuid(),
    imageId: z.string().uuid(),
    userId: z.string().uuid(),
    isPicked: z.boolean(),
    isRejected: z.boolean(),
    rating: z.number().nullable(),
    selectedAt: z.string().datetime(),
    updatedAt: z.string().datetime(),
    });

const ObjectTagSchema = z.object({
    id: z.string().uuid(),
    imageId: z.string().uuid(),
    tagName: z.string(),
    tagCategory: z.string().nullable(),
    confidence: z.string().nullable(),
    boundingBoxX: z.number().nullable(),
    boundingBoxY: z.number().nullable(),
    boundingBoxWidth: z.number().nullable(),
    boundingBoxHeight: z.number().nullable(),
    modelVersion: z.string(),
    updatedAt: z.string().datetime(),
    createdAt: z.string().datetime(),
    });

const ImageDetailSchema = z.object({
    image: ImageSchema,
    qualityScore: QualityScoreSchema.nullable(),
    imageSelection: ImageSelectionSchema.nullable(),
    objectTags: z.array(ObjectTagSchema),
  });

const ErrorSchema = z.object({
  error: z.string(),
});

const getProjectsRoute = createRoute({
  method: 'get',
  path: '/',
  summary: 'Get a list of projects',
  description: 'Retrieves a list of all projects for the authenticated user.',
  responses: {
    200: {
      description: 'Successful response with a list of projects.',
      content: {
        'application/json': {
          schema: z.array(ProjectSchema),
        },
      },
    },
    401: {
        description: 'Unauthorized access.',
        content: {
            'application/json': {
            schema: ErrorSchema,
            },
        },
    },
  },
});

app.openapi(getProjectsRoute, async (c) => {
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const projectList = await db
        .select()
        .from(project)
        .where(eq(project.userId, user.id));

    return c.json(projectList);
});

const createProjectRoute = createRoute({
    method: 'post',
    path: '/',
    summary: 'Create a new project',
    description: 'Creates a new project for the authenticated user.',
    request: {
        body: {
            content: {
                'application/json': {
                    schema: z.object({
                        name: z.string().max(100),
                        description: z.string().optional(),
                    }),
                },
            },
        },
    },
    responses: {
        201: {
            description: 'Successful response with the newly created project.',
            content: {
                'application/json': {
                    schema: ProjectSchema,
                },
            },
        },
        401: {
            description: 'Unauthorized access.',
            content: {
                'application/json': {
                schema: ErrorSchema,
                },
            },
        },
    },
});

app.openapi(createProjectRoute, async (c) => {
    const { name, description } = c.req.valid('json');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const newProject = await db
        .insert(project)
        .values({
            projectName: name,
            description,
            userId: user.id,
        })
        .returning();

    return c.json(newProject[0], 201);
});

const getProjectImagesRoute = createRoute({
    method: 'get',
    path: '/{projectId}/images',
    summary: 'Get a list of images in a project',
    description: 'Retrieves a paginated and filtered list of images within a specific project.',
    request: {
        params: z.object({
            projectId: z.string().uuid(),
        }),
        query: z.object({
            viewType: z.enum(['ALL', 'PICKED', 'TRASH', 'BEST_SHOTS']).default('ALL'),
            minQualityScore: z.coerce.number().optional(),
            nextCursor: z.string().optional(),
        }),
    },
    responses: {
        200: {
            description: 'Successful response with a list of images, pagination details, and object tags.',
            content: {
                'application/json': {
                    schema: z.object({
                        data: z.array(ImageDetailSchema),
                        nextCursor: z.string().nullable(),
                    }),
                },
            },
        },
        401: {
            description: 'Unauthorized access.',
            content: {
                'application/json': {
                schema: ErrorSchema,
                },
            },
        },
    },
});

app.openapi(getProjectImagesRoute, async (c) => {
    const { projectId } = c.req.param();
    const { viewType, minQualityScore, nextCursor } = c.req.valid('query');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    let query = db
        .select({
            image: image,
            qualityScore: qualityScore,
            imageSelection: imageSelection,
        })
        .from(image)
        .where(eq(image.projectId, projectId))
        .leftJoin(qualityScore, eq(qualityScore.imageId, image.id))
        .leftJoin(imageSelection, eq(imageSelection.imageId, image.id));

    if (viewType === 'PICKED') {
        query.where(eq(imageSelection.isPicked, true));
    } else if (viewType === 'TRASH') {
        query.where(eq(imageSelection.isRejected, true));
    } else if (viewType === 'BEST_SHOTS') {
        query.orderBy(desc(qualityScore.musiqScore));
    }

    if (minQualityScore) {
        query.where(gt(qualityScore.musiqScore, minQualityScore.toString()));
    }

    const limit = 20;
    if (nextCursor) {
        query.where(gt(image.id, nextCursor));
    }
    query.limit(limit);

    const imageList = await query;

    if (imageList.length === 0) {
        return c.json({ data: [], nextCursor: null });
    }

    const imageIds = imageList.map(i => i.image.id);
    const tags = await db
        .select()
        .from(objectTag)
        .where(inArray(objectTag.imageId, imageIds));

    const tagsByImageId = tags.reduce((acc, tag) => {
        if (!acc[tag.imageId]) {
            acc[tag.imageId] = [];
        }
        acc[tag.imageId].push(tag);
        return acc;
    }, {});

    const responseData = imageList.map(i => ({
        ...i,
        objectTags: tagsByImageId[i.image.id] || [],
    }));

    const lastImage = imageList[imageList.length - 1];
    const newNextCursor = lastImage ? lastImage.image.id : null;

    return c.json({ data: responseData, nextCursor: newNextCursor });
});

const uploadProjectImagesRoute = createRoute({
    method: 'post',
    path: '/{projectId}/images',
    summary: 'Upload images to a project',
    description: 'Handles the upload of one or more images to a project.',
    request: {
        params: z.object({
            projectId: z.string().uuid(),
        }),
        body: {
            content: {
                'multipart/form-data': {
                    schema: z.object({
                        'files[]': z.array(z.instanceof(File)),
                    }),
                },
            },
        },
    },
    responses: {
        202: {
            description: 'Successful response indicating the upload is being processed.',
            content: {
                'application/json': {
                    schema: z.object({
                        message: z.string(),
                    }),
                },
            },
        },
        401: {
            description: 'Unauthorized access.',
            content: {
                'application/json': {
                schema: ErrorSchema,
                },
            },
        },
    },
});

app.openapi(uploadProjectImagesRoute, async (c) => {
    const { projectId } = c.req.param();
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const body = await c.req.parseBody();
    const files = body['files[]'] as File[];

    const storagePath = `storage/images/${projectId}`;
    await mkdir(storagePath, { recursive: true });

    for (const file of files) {
        const imageId = uuidv4();
        const filePath = `${storagePath}/${imageId}`;
        const buffer = await file.arrayBuffer();
        await writeFile(filePath, Buffer.from(buffer));

        await db.insert(image).values({
            id: imageId,
            projectId,
            userId: user.id,
            originalFilename: file.name,
            storagePath: filePath,
            fileSizeBytes: file.size,
            mimeType: file.type,
        });
    }

    return c.json({ message: 'Upload successful' }, 202);
});

const analyzeProjectRoute = createRoute({
    method: 'post',
    path: '/{projectId}/analyze',
    summary: 'Analyze a project',
    description: 'Initiates an analysis job for all images in a project.',
    request: {
        params: z.object({
            projectId: z.string().uuid(),
        }),
        body: {
            content: {
                'application/json': {
                    schema: z.object({
                        jobType: z.enum(['FULL_SCAN', 'OBJECT_DETECTION_ONLY', 'SCORING_ONLY']).default('FULL_SCAN'),
                    }),
                },
            },
        },
    },
    responses: {
        202: {
            description: 'Successful response with the details of the new analysis job.',
            content: {
                'application/json': {
                    schema: z.any(),
                },
            },
        },
        401: {
            description: 'Unauthorized access.',
            content: {
                'application/json': {
                schema: ErrorSchema,
                },
            },
        },
    },
});

app.openapi(analyzeProjectRoute, async (c) => {
    const { projectId } = c.req.param();
    const { jobType } = c.req.valid('json');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const newJob = await db.insert(analysisJob).values({
        projectId,
        userId: user.id,
        jobType,
    }).returning();

    const imagesToAnalyze = await db.select().from(image).where(eq(image.projectId, projectId));

    const jobItems = [];
    for (const imageToAnalyze of imagesToAnalyze) {
        const newJobItem = await db.insert(analysisJobItem).values({
            jobId: newJob[0].id,
            imageId: imageToAnalyze.id,
        }).returning();
        jobItems.push(newJobItem[0]);
    }

    let task_name = 'quality_assessment';
    if (jobType === 'OBJECT_DETECTION_ONLY') {
        task_name = 'object_detection';
    }

    const batchRequest = {
        requests: jobItems.map(item => ({
            image_id: item.imageId,
            task_name,
            job_item_id: item.id,
        })),
    };

    const aiServiceUrl = c.env.AI_SERVICE_URL || 'http://localhost:8001';
    await fetch(`${aiServiceUrl}/batch-analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(batchRequest),
    });

    return c.json(newJob[0], 202);
});

const getAnalysisStatusRoute = createRoute({
    method: 'get',
    path: '/{projectId}/analysis/status',
    summary: 'Get analysis status',
    description: 'Retrieves the status of the latest analysis job for a project.',
    request: {
        params: z.object({
            projectId: z.string().uuid(),
        }),
    },
    responses: {
        200: {
            description: 'Successful response with the job status and progress.',
            content: {
                'application/json': {
                    schema: z.object({
                        jobId: z.string().uuid(),
                        status: z.string(),
                        progressPercentage: z.number(),
                        completedItems: z.number(),
                        totalItems: z.number(),
                    }),
                },
            },
        },
        401: {
            description: 'Unauthorized access.',
            content: {
                'application/json': {
                schema: ErrorSchema,
                },
            },
        },
        404: {
            description: 'No analysis job found.',
            content: {
                'application/json': {
                schema: ErrorSchema,
                },
            },
        },
    },
});

app.openapi(getAnalysisStatusRoute, async (c) => {
    const { projectId } = c.req.param();
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const latestJob = await db
        .select()
        .from(analysisJob)
        .where(and(eq(analysisJob.projectId, projectId), eq(analysisJob.userId, user.id)))
        .orderBy(desc(analysisJob.createdAt))
        .limit(1);

    if (latestJob.length === 0) {
        return c.json({ error: 'No analysis job found' }, 404);
    }

    const jobItems = await db
        .select()
        .from(analysisJobItem)
        .where(eq(analysisJobItem.jobId, latestJob[0].id));

    const completedItems = jobItems.filter(item => item.itemStatus === 'completed').length;
    const totalItems = jobItems.length;
    const progressPercentage = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;

    return c.json({
        jobId: latestJob[0].id,
        status: latestJob[0].jobStatus,
        progressPercentage,
        completedItems,
        totalItems,
    });
});

export default app;
