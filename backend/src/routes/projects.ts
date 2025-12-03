/**
 * @module routes/projects
 * This file defines the API routes for managing projects, including creating projects,
 * retrieving project details, and handling image uploads and analysis within a project.
 */
import { OpenAPIHono, createRoute, extendZodWithOpenApi } from '@hono/zod-openapi';
import type { RouteHandler } from '@hono/zod-openapi';
import { z } from 'zod';
import { db } from '../db';
import { project, image, qualityScore, imageSelection, objectTag, analysisJob, analysisJobItem, imageGroup, imageGroupMembership } from '../db/schema';
import { eq, and, gt, desc, inArray, sql, isNull } from 'drizzle-orm';
import type { SQL } from 'drizzle-orm';
import { mkdir, writeFile } from 'fs/promises';
import { randomUUID } from 'crypto';
import * as path from 'path';
import { AuthType } from '../lib/auth';

extendZodWithOpenApi(z);

type Variables = {
  user: AuthType['user'];
  session: AuthType['session'];
};

type Bindings = {
  AI_SERVICE_URL?: string;
};

type AppEnv = {
  Bindings: Bindings;
  Variables: Variables;
};

type AppRouteHandler<R extends ReturnType<typeof createRoute>> = RouteHandler<R, AppEnv>;

const app = new OpenAPIHono<AppEnv>();

const ProjectSchema = z.object({
  id: z.uuid(),
  userId: z.uuid(),
  projectName: z.string(),
  description: z.string().nullable(),
  coverImageId: z.string().nullable(),
  isArchived: z.boolean(),
  createdAt: z.iso.datetime(),
  updatedAt: z.iso.datetime(),
  archivedAt: z.iso.datetime().nullable(),
});

const ImageSchema = z.object({
    id: z.uuid(),
    userId: z.uuid().nullable(),
    projectId: z.uuid(),
    originalFilename: z.string(),
    storagePath: z.string(),
    thumbnailPath: z.string().nullable(),
    fileSizeBytes: z.number(),
    mimeType: z.string(),
    widthPx: z.number().nullable(),
    heightPx: z.number().nullable(),
    compareViewSelected: z.boolean(),
    captureDatetime: z.iso.datetime().nullable(),
    uploadDatetime: z.iso.datetime(),
    createdAt: z.iso.datetime(),
    updatedAt: z.iso.datetime(),
  });

const QualityScoreSchema = z.object({
    id: z.uuid(),
    imageId: z.uuid(),
    brisqueScore: z.string().nullable(),
    tenegradScore: z.string().nullable(),
    musiqScore: z.string().nullable(),
    modelVersion: z.string(),
    updatedAt: z.iso.datetime(),
    createdAt: z.iso.datetime(),
    });

const ImageSelectionSchema = z.object({
    id: z.uuid(),
    imageId: z.uuid(),
    userId: z.uuid(),
    isPicked: z.boolean(),
    isRejected: z.boolean(),
    rating: z.number().nullable(),
    selectedAt: z.iso.datetime(),
    updatedAt: z.iso.datetime(),
    });

const ObjectTagSchema = z.object({
    id: z.uuid(),
    imageId: z.uuid(),
    tagName: z.string(),
    tagCategory: z.string().nullable(),
    confidence: z.string().nullable(),
    boundingBoxX: z.number().nullable(),
    boundingBoxY: z.number().nullable(),
    boundingBoxWidth: z.number().nullable(),
    boundingBoxHeight: z.number().nullable(),
    modelVersion: z.string(),
    updatedAt: z.iso.datetime(),
    createdAt: z.iso.datetime(),
    });

const ImageDetailSchema = z.object({
    image: ImageSchema,
    qualityScore: QualityScoreSchema.nullable(),
    imageSelection: ImageSelectionSchema.nullable(),
    objectTags: z.array(ObjectTagSchema),
  });

type ObjectTagRow = typeof objectTag.$inferSelect;

const ErrorSchema = z.object({
  error: z.string(),
});

const FileUploadSchema = z
  .instanceof(File)
  .openapi({
    type: 'string',
    format: 'binary',
    description: 'Binary image file uploaded via multipart/form-data.',
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

const getProjectsHandler: AppRouteHandler<typeof getProjectsRoute> = async (c) => {
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const projectList = await db
        .select()
        .from(project)
        .where(eq(project.userId, user.id));

    return c.json(projectList, 200);
};

app.openapi(getProjectsRoute, getProjectsHandler);

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

const createProjectHandler: AppRouteHandler<typeof createProjectRoute> = async (c) => {
    const { name, description } = c.req.valid('json');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const projectId = randomUUID();
    const [newProject] = await db
        .insert(project)
        .values({
            id: projectId,
            projectName: name,
            description,
            userId: user.id,
        })
        .returning();

    return c.json(newProject, 201);
};

app.openapi(createProjectRoute, createProjectHandler);

const getProjectImagesRoute = createRoute({
    method: 'get',
    path: '/{projectId}/images',
    summary: 'Get a list of images in a project',
    description: 'Retrieves a paginated and filtered list of images within a specific project.',
    request: {
        params: z.object({
            projectId: z.uuid(),
        }),
        query: z.object({
            viewType: z.enum(['ALL', 'PICKED', 'TRASH', 'BEST_SHOTS']).default('ALL'),
            compareViewSelected: z.enum(['true', 'false']).optional(),
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

const getProjectImagesHandler: AppRouteHandler<typeof getProjectImagesRoute> = async (c) => {
    const { projectId } = c.req.param();
    const { viewType, compareViewSelected, minQualityScore, nextCursor } = c.req.valid('query');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const limit = 20;
    const filters: SQL[] = [eq(image.projectId, projectId)];

    if (viewType === 'PICKED') {
        filters.push(eq(imageSelection.isPicked, true));
    } else if (viewType === 'TRASH') {
        filters.push(eq(imageSelection.isRejected, true));
    }

    if (compareViewSelected) {
        const compareViewSelectedBool = compareViewSelected === 'true';
        filters.push(eq(image.compareViewSelected, compareViewSelectedBool));
    }

    if (typeof minQualityScore === 'number' && !Number.isNaN(minQualityScore)) {
        filters.push(gt(qualityScore.musiqScore, minQualityScore.toString()));
    }

    if (nextCursor) {
        filters.push(gt(image.id, nextCursor));
    }

    const whereClause = filters.length === 1 ? filters[0] : and(...filters)!;

    const baseQuery = db
        .select({
            image,
            qualityScore,
            imageSelection,
        })
        .from(image)
        .leftJoin(qualityScore, eq(qualityScore.imageId, image.id))
        .leftJoin(imageSelection, eq(imageSelection.imageId, image.id))
        .where(whereClause);

    const orderedQuery = viewType === 'BEST_SHOTS'
        ? baseQuery.orderBy(desc(qualityScore.musiqScore))
        : baseQuery.orderBy(desc(image.createdAt));

    const imageList = await orderedQuery.limit(limit);

    if (imageList.length === 0) {
        return c.json({ data: [], nextCursor: null }, 200);
    }

    const imageIds = imageList.map(i => i.image.id);
    const tags = await db
        .select()
        .from(objectTag)
        .where(inArray(objectTag.imageId, imageIds));

    const tagsByImageId = tags.reduce<Record<string, ObjectTagRow[]>>((acc, tag) => {
        if (!acc[tag.imageId]) {
            acc[tag.imageId] = [];
        }
        acc[tag.imageId].push(tag);
        return acc;
    }, {});

    const responseData = imageList.map(i => ({
        ...i,
        objectTags: tagsByImageId[i.image.id] ?? [],
    }));

    const lastImage = imageList[imageList.length - 1];
    const newNextCursor = lastImage ? lastImage.image.id : null;

    return c.json({ data: responseData, nextCursor: newNextCursor }, 200);
};

app.openapi(getProjectImagesRoute, getProjectImagesHandler);

const uploadProjectImagesRoute = createRoute({
    method: 'post',
    path: '/{projectId}/images',
    summary: 'Upload images to a project',
    description: 'Handles the upload of one or more images to a project.',
    request: {
        params: z.object({
            projectId: z.uuid(),
        }),
        body: {
            content: {
                'multipart/form-data': {
                    schema: z.object({
                        'files[]': z.array(FileUploadSchema).min(1),
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

const uploadProjectImagesHandler: AppRouteHandler<typeof uploadProjectImagesRoute> = async (c) => {
    const { projectId } = c.req.param();
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const body = await c.req.parseBody();
    const parsedFiles = body['files[]'];
    const files = (Array.isArray(parsedFiles) ? parsedFiles : parsedFiles ? [parsedFiles] : [])
        .filter((file): file is File => file instanceof File);

    const storagePath = `storage/images/${projectId}`;
    await mkdir(storagePath, { recursive: true });

    const [currentProject] = await db
        .select({ coverImageId: project.coverImageId })
        .from(project)
        .where(eq(project.id, projectId));

    let isFirstImage = !currentProject?.coverImageId;
    const uploadedImageIds: string[] = [];

    for (const file of files) {
        const imageId = randomUUID();
        const extension = path.extname(file.name);
        const filePath = `${storagePath}/${imageId}${extension}`;
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

        uploadedImageIds.push(imageId);

        if (isFirstImage) {
            await db.update(project)
                .set({ coverImageId: imageId, updatedAt: new Date() })
                .where(eq(project.id, projectId));
            isFirstImage = false;
        }
    }

    // Trigger analysis for uploaded images
    if (uploadedImageIds.length > 0) {
        const jobId = randomUUID();
        const [newJob] = await db.insert(analysisJob).values({
            id: jobId,
            projectId,
            userId: user.id,
            jobType: 'exif_analysis', // Using a specific job type for upload triggers
        }).returning();

        const jobItemsToInsert: typeof analysisJobItem.$inferInsert[] = [];
        const batchRequestRequests: { image_id: string; task_name: string; job_item_id: string }[] = [];

        const tasks = ['thumbnail_generation', 'exif_analysis'];
        for (const imgId of uploadedImageIds) {
            for (const task of tasks) {
                const jobItemId = randomUUID();
                jobItemsToInsert.push({
                    id: jobItemId,
                    jobId: newJob.id,
                    imageId: imgId,
                });
                batchRequestRequests.push({
                    image_id: imgId,
                    task_name: task,
                    job_item_id: jobItemId,
                });
            }
        }

        await db.insert(analysisJobItem).values(jobItemsToInsert);

        const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:8001';
        // Fire and forget - don't await the fetch to not block the upload response
        fetch(`${aiServiceUrl}/batch-analyze`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ requests: batchRequestRequests }),
        }).catch(err => console.error('Failed to trigger background analysis:', err));
    }

    return c.json({ message: 'Upload successful' }, 202);
};

app.openapi(uploadProjectImagesRoute, uploadProjectImagesHandler);

const analyzeProjectRoute = createRoute({
    method: 'post',
    path: '/{projectId}/analyze',
    summary: 'Analyze a project',
    description: 'Initiates an analysis job for all images in a project.',
    request: {
        params: z.object({
            projectId: z.uuid(),
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

type AnalyzeProjectRequestBody = z.infer<
    typeof analyzeProjectRoute['request']['body']['content']['application/json']['schema']
>;

const apiJobTypeToDbJobType: Record<
    AnalyzeProjectRequestBody['jobType'],
    typeof analysisJob.$inferInsert['jobType']
> = {
    FULL_SCAN: 'quality_analysis',
    OBJECT_DETECTION_ONLY: 'object_detection',
    SCORING_ONLY: 'quality_analysis',
};

const analyzeProjectHandler: AppRouteHandler<typeof analyzeProjectRoute> = async (c) => {
    const { projectId } = c.req.param();
    const { jobType } = c.req.valid('json');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const jobId = randomUUID();
    const [newJob] = await db.insert(analysisJob).values({
        id: jobId,
        projectId,
        userId: user.id,
        jobType: apiJobTypeToDbJobType[jobType],
    }).returning();

    const imagesToAnalyze = await db.select().from(image).where(eq(image.projectId, projectId));

    let tasks: string[] = [];
    if (jobType === 'FULL_SCAN') {
        tasks = ['quality_assessment', 'object_detection', 'image_captioning', 'exif_analysis', 'similarity_grouping', 'gps_grouping'];
    } else if (jobType === 'OBJECT_DETECTION_ONLY') {
        tasks = ['object_detection'];
    } else if (jobType === 'SCORING_ONLY') {
        tasks = ['quality_assessment'];
    }

    const jobItemsToInsert: typeof analysisJobItem.$inferInsert[] = [];
    const batchRequestRequests: { image_id: string; task_name: string; job_item_id: string }[] = [];

    for (const imageToAnalyze of imagesToAnalyze) {
        for (const task of tasks) {
            const jobItemId = randomUUID();
            jobItemsToInsert.push({
                id: jobItemId,
                jobId: newJob.id,
                imageId: imageToAnalyze.id,
            });
            batchRequestRequests.push({
                image_id: imageToAnalyze.id,
                task_name: task,
                job_item_id: jobItemId,
            });
        }
    }

    if (jobItemsToInsert.length > 0) {
        // Process in chunks to avoid query size limits
        const chunkSize = 100;
        for (let i = 0; i < jobItemsToInsert.length; i += chunkSize) {
            await db.insert(analysisJobItem).values(jobItemsToInsert.slice(i, i + chunkSize));
        }
    }

    const batchRequest = {
        requests: batchRequestRequests,
    };

    const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:8001';
    await fetch(`${aiServiceUrl}/batch-analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(batchRequest),
    });

    return c.json(newJob, 202);
};

app.openapi(analyzeProjectRoute, analyzeProjectHandler);

const getAnalysisStatusRoute = createRoute({
    method: 'get',
    path: '/{projectId}/analysis/status',
    summary: 'Get analysis status',
    description: 'Retrieves the status of the latest analysis job for a project.',
    request: {
        params: z.object({
            projectId: z.uuid(),
        }),
    },
    responses: {
        200: {
            description: 'Successful response with the job status and progress.',
            content: {
                'application/json': {
                    schema: z.object({
                        jobId: z.uuid(),
                        status: z.string(),
                        progressPercentage: z.number(),
                        completedItems: z.number(),
                        skippedItems: z.number(),
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

const getAnalysisStatusHandler: AppRouteHandler<typeof getAnalysisStatusRoute> = async (c) => {
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
    const failedItems = jobItems.filter(item => item.itemStatus === 'failed').length;
    const skippedItems = jobItems.filter(item => item.itemStatus === 'skipped').length;
    const processingItems = jobItems.filter(item => item.itemStatus === 'processing').length;
    const totalItems = jobItems.length;
    
    // Calculate progress based on items that have reached a terminal state (completed, failed, or skipped)
    const processedItems = completedItems + failedItems + skippedItems;
    const progressPercentage = totalItems > 0 ? (processedItems / totalItems) * 100 : 0;

    let newStatus = latestJob[0].jobStatus;

    if (totalItems > 0) {
        if (processedItems === totalItems) {
            newStatus = 'completed';
        } else if (processedItems > 0 || processingItems > 0) {
            if (newStatus === 'pending') {
                newStatus = 'processing';
            }
        }
    }

    if (newStatus !== latestJob[0].jobStatus) {
        await db.update(analysisJob)
            .set({ 
                jobStatus: newStatus,
                completedAt: newStatus === 'completed' ? new Date() : null,
                updatedAt: new Date(),
            })
            .where(eq(analysisJob.id, latestJob[0].id));
        
        latestJob[0].jobStatus = newStatus;
    }

    return c.json({
        jobId: latestJob[0].id,
        status: latestJob[0].jobStatus,
        progressPercentage,
        completedItems,
        skippedItems,
        totalItems,
    }, 200);
};

app.openapi(getAnalysisStatusRoute, getAnalysisStatusHandler);

const getProjectDetectedObjectsRoute = createRoute({
  method: 'get',
  path: '/{projectId}/detected-objects',
  summary: 'Get detected objects in a project',
  description: 'Retrieves a list of all unique detected objects found in images belonging to a specific project.',
  request: {
    params: z.object({
      projectId: z.uuid(),
    }),
  },
  responses: {
    200: {
      description: 'Successful response with a list of unique detected object tags.',
      content: {
        'application/json': {
          schema: z.array(z.string()),
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

app.openapi(getProjectDetectedObjectsRoute, async (c) => {
  const { projectId } = c.req.param();
  const user = c.get('user');

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  // Ensure user owns the project or has access to it
  const projectCheck = await db
    .select()
    .from(project)
    .where(and(eq(project.id, projectId), eq(project.userId, user.id)))
    .limit(1);

  if (projectCheck.length === 0) {
     // If user doesn't own project, check if they own images in it (less likely but possible with sharing logic)
     // For now, strict project ownership check as per other routes
     return c.json([], 200); // Or 404/403
  }

  const detectedObjects = await db
    .select({ tagName: objectTag.tagName })
    .from(objectTag)
    .innerJoin(image, eq(objectTag.imageId, image.id))
    .where(eq(image.projectId, projectId))
    .groupBy(objectTag.tagName)
    .orderBy(objectTag.tagName);

  return c.json(detectedObjects.map(d => d.tagName), 200);
});

const ImageGroupSchema = z.object({
  id: z.string(),
  projectId: z.string(),
  groupType: z.enum(['similar', 'burst', 'sequence', 'time_based', 'gps']),
  representativeImageId: z.string().nullable(),
  timeRangeStart: z.string().datetime().nullable(),
  timeRangeEnd: z.string().datetime().nullable(),
  similarityScore: z.string().nullable(),
  memberCount: z.number(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});


const generateThumbnailsRoute = createRoute({
    method: 'post',
    path: '/{projectId}/generate-thumbnails',
    summary: 'Trigger thumbnail generation',
    description: 'Triggers thumbnail generation for all images in a project that do not have one.',
    request: {
        params: z.object({
            projectId: z.uuid(),
        }),
    },
    responses: {
        202: {
            description: 'Thumbnail generation triggered.',
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

const generateThumbnailsHandler: AppRouteHandler<typeof generateThumbnailsRoute> = async (c) => {
    const { projectId } = c.req.param();
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    // Find images without thumbnails
    const imagesWithoutThumbnails = await db
        .select({ id: image.id })
        .from(image)
        .where(and(eq(image.projectId, projectId), isNull(image.thumbnailPath)));

    if (imagesWithoutThumbnails.length === 0) {
        return c.json({ message: 'All images already have thumbnails.' }, 202);
    }

    const jobId = randomUUID();
    await db.insert(analysisJob).values({
        id: jobId,
        projectId,
        userId: user.id,
        jobType: 'thumbnail_generation',
    });

    const jobItemsToInsert: typeof analysisJobItem.$inferInsert[] = [];
    const batchRequestRequests: { image_id: string; task_name: string; job_item_id: string }[] = [];

    for (const img of imagesWithoutThumbnails) {
        const jobItemId = randomUUID();
        jobItemsToInsert.push({
            id: jobItemId,
            jobId: jobId,
            imageId: img.id,
        });
        batchRequestRequests.push({
            image_id: img.id,
            task_name: 'thumbnail_generation',
            job_item_id: jobItemId,
        });
    }

    // Chunk inserts
    const chunkSize = 100;
    for (let i = 0; i < jobItemsToInsert.length; i += chunkSize) {
        await db.insert(analysisJobItem).values(jobItemsToInsert.slice(i, i + chunkSize));
    }

    const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:8001';
    fetch(`${aiServiceUrl}/batch-analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ requests: batchRequestRequests }),
    }).catch(err => console.error('Failed to trigger thumbnail generation:', err));

    return c.json({ message: `Triggered thumbnail generation for ${imagesWithoutThumbnails.length} images.` }, 202);
};

app.openapi(generateThumbnailsRoute, generateThumbnailsHandler);


const getProjectGroupsRoute = createRoute({
  method: 'get',
  path: '/{projectId}/groups',
  summary: 'Get image groups in a project',
  description: 'Retrieves a list of image groups (clusters) for a specific project.',
  request: {
    params: z.object({
      projectId: z.uuid(),
    }),
  },
  responses: {
    200: {
      description: 'Successful response with a list of image groups.',
      content: {
        'application/json': {
          schema: z.array(ImageGroupSchema),
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

app.openapi(getProjectGroupsRoute, async (c) => {
  const { projectId } = c.req.param();
  const user = c.get('user');

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  const projectCheck = await db
    .select()
    .from(project)
    .where(and(eq(project.id, projectId), eq(project.userId, user.id)))
    .limit(1);

  if (projectCheck.length === 0) {
    return c.json([], 200);
  }

  const groups = await db
    .select({
      id: imageGroup.id,
      projectId: imageGroup.projectId,
      groupType: imageGroup.groupType,
      representativeImageId: imageGroup.representativeImageId,
      timeRangeStart: imageGroup.timeRangeStart,
      timeRangeEnd: imageGroup.timeRangeEnd,
      similarityScore: imageGroup.similarityScore,
      createdAt: imageGroup.createdAt,
      updatedAt: imageGroup.updatedAt,
      memberCount: sql<number>`count(${imageGroupMembership.id})::int`,
    })
    .from(imageGroup)
    .leftJoin(imageGroupMembership, eq(imageGroupMembership.groupId, imageGroup.id))
    .where(eq(imageGroup.projectId, projectId))
    .groupBy(imageGroup.id);

  const formattedGroups = groups.map((g) => ({
    ...g,
    timeRangeStart: g.timeRangeStart?.toISOString() ?? null,
    timeRangeEnd: g.timeRangeEnd?.toISOString() ?? null,
    createdAt: g.createdAt.toISOString(),
    updatedAt: g.updatedAt.toISOString(),
  }));

  return c.json(formattedGroups, 200);
});

export default app;
