/**
 * @module routes/images
 * This file defines the API routes for managing and retrieving images.
 */
import { OpenAPIHono, createRoute } from '@hono/zod-openapi';
import { z } from 'zod';
import { db } from '../db';
import {
  image as imageTable,
  imageSelection,
  userRejectionReason,
  imageGroupMembership,
  project,
  qualityScore,
  imageCaption,
  objectTag,
  imageEXIF,
  imageGPS,
} from '../db/schema';
import { eq, and, or, ilike, gt, desc, asc, sql, exists, inArray, SQL } from 'drizzle-orm';
import { AuthType } from '../lib/auth';
import { randomUUID } from 'crypto';

type Variables = {
  user: AuthType['user'];
  session: AuthType['session'];
};

const app = new OpenAPIHono<{ Variables: Variables }>();

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
  groupIds: z.array(z.string()),
});

const ImageEXIFSchema = z.object({
    cameraMake: z.string().nullable(),
    cameraModel: z.string().nullable(),
    lensMake: z.string().nullable(),
    lensModel: z.string().nullable(),
    focalLengthMm: z.string().nullable(),
    apertureF: z.string().nullable(),
    shutterSpeed: z.string().nullable(),
    iso: z.number().nullable(),
    exposureCompensation: z.string().nullable(),
    flashFired: z.boolean().nullable(),
    whiteBalance: z.string().nullable(),
    shootingMode: z.string().nullable(),
    orientation: z.number().nullable(),
});

const ImageGPSSchema = z.object({
    latitude: z.string(),
    longitude: z.string(),
    altitudeM: z.string().nullable(),
});

const ImageCaptionSchema = z.object({
    id: z.uuid(),
    caption: z.string(),
    modelVersion: z.string(),
    createdAt: z.iso.datetime(),
});

const ImageFullDetailSchema = z.object({
  image: ImageSchema,
  exif: ImageEXIFSchema.nullable(),
  gps: ImageGPSSchema.nullable(),
  qualityScore: QualityScoreSchema.nullable(),
  imageSelection: ImageSelectionSchema.nullable(),
  objectTags: z.array(ObjectTagSchema),
  captions: z.array(ImageCaptionSchema),
});

const ErrorSchema = z.object({
  error: z.string(),
});

const getImagesRoute = createRoute({
  method: 'get',
  path: '/',
  summary: 'Get a list of images',
  description: 'Retrieves a paginated and filtered list of images for the authenticated user.',
  request: {
    query: z.object({
      q: z.string().optional(),
      groupId: z.string().optional(),
      projectId: z.string().optional(),
      isPicked: z.enum(['true', 'false']).optional(),
      isRejected: z.enum(['true', 'false']).optional(),
      compareViewSelected: z.enum(['true', 'false']).optional(),
      minQualityScore: z.coerce.number().optional(),
      rating: z.coerce.number().int().min(0).max(5).optional(),
      page: z.coerce.number().min(1).default(1),
      limit: z.coerce.number().min(1).max(100).default(20),
      sort: z.string().optional(),
      order: z.enum(['asc', 'desc']).default('desc'),
    }),
  },
  responses: {
    200: {
      description: 'Successful response with a list of images.',
      content: {
        'application/json': {
          schema: z.object({
            data: z.array(ImageDetailSchema),
            page: z.number(),
            limit: z.number(),
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

app.openapi(getImagesRoute, async (c) => {
    const {
      q,
      groupId,
      projectId,
      isPicked,
      isRejected,
      compareViewSelected,
      minQualityScore,
      rating,
      page,
      limit,
      sort,
      order,
    } = c.req.valid('query');
    const user = c.get('user');

    if (!user) {
      return c.json({ error: 'Unauthorized' }, 401);
    }

    const offset = (page - 1) * limit;
    const filters: (SQL | undefined)[] = [];

    // Mandatory filter: User ownership
    filters.push(
      or(
        eq(imageTable.userId, user.id),
        and(
          eq(project.userId, user.id),
          eq(imageTable.projectId, project.id)
        )
      )
    );

    // Optional filters
    if (projectId) {
      filters.push(eq(imageTable.projectId, projectId));
    }

    if (groupId) {
      const groupExists = exists(
          db.select()
          .from(imageGroupMembership)
          .where(and(
              eq(imageGroupMembership.imageId, imageTable.id),
              eq(imageGroupMembership.groupId, groupId)
          ))
      );
      filters.push(groupExists);
    }

    if (isPicked) {
      const isPickedBool = isPicked === 'true';
      filters.push(eq(imageSelection.isPicked, isPickedBool));
    }

    if (isRejected) {
      const isRejectedBool = isRejected === 'true';
      filters.push(eq(imageSelection.isRejected, isRejectedBool));
    }

    if (compareViewSelected) {
      const compareViewSelectedBool = compareViewSelected === 'true';
      filters.push(eq(imageTable.compareViewSelected, compareViewSelectedBool));
    }

    if (rating !== undefined) {
      filters.push(eq(imageSelection.rating, rating));
    }

    if (minQualityScore !== undefined) {
      filters.push(gt(qualityScore.musiqScore, minQualityScore.toString()));
    }

    if (q) {
      const searchPattern = `%${q}%`;
      const captionExists = exists(
        db
          .select()
          .from(imageCaption)
          .where(
            and(
              eq(imageCaption.imageId, imageTable.id),
              ilike(imageCaption.caption, searchPattern)
            )
          )
      );

      const tagExists = exists(
        db
          .select()
          .from(objectTag)
          .where(
            and(
              eq(objectTag.imageId, imageTable.id),
              ilike(objectTag.tagName, searchPattern)
            )
          )
      );

      filters.push(or(captionExists, tagExists));
    }

    const query = db
      .select({
        image: imageTable,
        qualityScore: qualityScore,
        imageSelection: imageSelection,
      })
      .from(imageTable)
      .leftJoin(project, eq(imageTable.projectId, project.id))
      .leftJoin(imageSelection, and(eq(imageSelection.imageId, imageTable.id), eq(imageSelection.userId, user.id)))
      .leftJoin(qualityScore, eq(qualityScore.imageId, imageTable.id));

    const validFilters = filters.filter((f): f is SQL => f !== undefined);
    if (validFilters.length > 0) {
      query.where(and(...validFilters));
    }

    let orderByClause = desc(imageTable.createdAt); // Default
    if (sort) {
      const direction = order === 'asc' ? asc : desc;
      switch (sort) {
        case 'uploadDate':
          orderByClause = direction(imageTable.uploadDatetime);
          break;
        case 'captureDate':
          orderByClause = direction(imageTable.captureDatetime);
          break;
        case 'rating':
          orderByClause = direction(imageSelection.rating);
          break;
        case 'score':
        case 'qualityScore':
          orderByClause = direction(qualityScore.musiqScore);
          break;
        case 'createdAt':
          orderByClause = direction(imageTable.createdAt);
          break;
      }
    }
    query.orderBy(orderByClause);

    query.limit(limit).offset(offset);

    const imageList = await query;

    if (imageList.length > 0) {
      const imageIds = imageList.map((i) => i.image.id);
      const [tags, groupMemberships] = await Promise.all([
        db
          .select()
          .from(objectTag)
          .where(inArray(objectTag.imageId, imageIds)),
        db
          .select()
          .from(imageGroupMembership)
          .where(inArray(imageGroupMembership.imageId, imageIds))
      ]);

      const tagsByImageId = tags.reduce((acc, tag) => {
        if (!acc[tag.imageId]) {
          acc[tag.imageId] = [];
        }
        acc[tag.imageId].push(tag);
        return acc;
      }, {} as Record<string, typeof objectTag.$inferSelect[]>);

      const groupsByImageId = groupMemberships.reduce((acc, membership) => {
        if (!acc[membership.imageId]) {
          acc[membership.imageId] = [];
        }
        acc[membership.imageId].push(membership.groupId);
        return acc;
      }, {} as Record<string, string[]>);

      const responseData = imageList.map((i) => ({
        ...i,
        objectTags: tagsByImageId[i.image.id] || [],
        groupIds: groupsByImageId[i.image.id] || [],
      }));

      return c.json({
        data: responseData,
        page,
        limit,
      });
    }

    return c.json({
      data: [],
      page,
      limit,
    });
  });

const getImageDetailsRoute = createRoute({
  method: 'get',
  path: '/{imageId}/details',
  summary: 'Get full image details',
  description: 'Retrieves comprehensive details for a specific image including EXIF, object detection, captions, and scores.',
  request: {
    params: z.object({
      imageId: z.uuid(),
    }),
  },
  responses: {
    200: {
      description: 'Successful response with full image details.',
      content: {
        'application/json': {
          schema: ImageFullDetailSchema,
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
        description: 'Image not found or unauthorized.',
        content: {
            'application/json': {
            schema: ErrorSchema,
            },
        },
    },
  },
});

app.openapi(getImageDetailsRoute, async (c) => {
    const { imageId } = c.req.param();
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    // Check ownership/access
    const imageRecord = await db
      .select({
        image: imageTable,
        exif: imageEXIF,
        gps: imageGPS,
        qualityScore: qualityScore,
        imageSelection: imageSelection,
      })
      .from(imageTable)
      .leftJoin(imageEXIF, eq(imageEXIF.imageId, imageTable.id))
      .leftJoin(imageGPS, eq(imageGPS.imageId, imageTable.id))
      .leftJoin(qualityScore, eq(qualityScore.imageId, imageTable.id))
      .leftJoin(imageSelection, and(eq(imageSelection.imageId, imageTable.id), eq(imageSelection.userId, user.id)))
      .leftJoin(project, eq(imageTable.projectId, project.id))
      .where(and(
        eq(imageTable.id, imageId),
        or(
            eq(imageTable.userId, user.id),
            and(
                eq(project.userId, user.id),
                eq(imageTable.projectId, project.id)
            )
        )
      ))
      .limit(1);

    if (imageRecord.length === 0) {
        return c.json({ error: 'Image not found or unauthorized' }, 404);
    }

    const record = imageRecord[0];

    // Fetch related lists (tags, captions)
    const [tags, captions] = await Promise.all([
        db.select().from(objectTag).where(eq(objectTag.imageId, imageId)),
        db.select().from(imageCaption).where(eq(imageCaption.imageId, imageId))
    ]);

    // Helper to format dates
    const formatDate = (d: Date) => d.toISOString();

    return c.json({
        image: {
            ...record.image,
            captureDatetime: record.image.captureDatetime ? formatDate(record.image.captureDatetime) : null,
            uploadDatetime: formatDate(record.image.uploadDatetime),
            createdAt: formatDate(record.image.createdAt),
            updatedAt: formatDate(record.image.updatedAt),
        },
        exif: record.exif,
        gps: record.gps,
        qualityScore: record.qualityScore ? {
            ...record.qualityScore,
            updatedAt: formatDate(record.qualityScore.updatedAt),
            createdAt: formatDate(record.qualityScore.createdAt),
        } : null,
        imageSelection: record.imageSelection ? {
            ...record.imageSelection,
            selectedAt: formatDate(record.imageSelection.selectedAt),
            updatedAt: formatDate(record.imageSelection.updatedAt),
        } : null,
        objectTags: tags.map(t => ({
            ...t,
            updatedAt: formatDate(t.updatedAt),
            createdAt: formatDate(t.createdAt),
        })),
        captions: captions.map(c => ({
            ...c,
            createdAt: formatDate(c.createdAt),
        })),
    });
});

const getImageFileRoute = createRoute({
  method: 'get',
  path: '/{imageId}/file',
  summary: 'Get image file',
  description: 'Serves the actual image file. Requires authentication.',
  request: {
    params: z.object({
      imageId: z.uuid(),
    }),
  },
  responses: {
    200: {
      description: 'The image file.',
      content: {
        'image/*': {
          schema: z.string().openapi({ format: 'binary' }),
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
        description: 'Image not found or unauthorized.',
        content: {
            'application/json': {
            schema: ErrorSchema,
            },
        },
    },
  },
});

app.openapi(getImageFileRoute, async (c) => {
    const { imageId } = c.req.param();
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const imageRecord = await db
        .select({
            storagePath: imageTable.storagePath,
            mimeType: imageTable.mimeType,
        })
        .from(imageTable)
        .where(and(eq(imageTable.id, imageId), eq(imageTable.userId, user.id))) // Ensure user owns the image (or project logic)
        .limit(1);
        
    // Note: The ownership check above restricts to images directly owned by user. 
    // If project sharing is involved, we might need to check project ownership/membership as well.
    // Since getImagesRoute checks "eq(imageTable.userId, user.id) OR (project.userId == user.id)", we should match that.
    
    if (imageRecord.length === 0) {
        // Try checking via project ownership if not direct owner
        const imageInProject = await db
            .select({
                storagePath: imageTable.storagePath,
                mimeType: imageTable.mimeType,
            })
            .from(imageTable)
            .innerJoin(project, eq(imageTable.projectId, project.id))
            .where(and(
                eq(imageTable.id, imageId),
                eq(project.userId, user.id)
            ))
            .limit(1);

        if (imageInProject.length > 0) {
             const file = Bun.file(imageInProject[0].storagePath);
             return new Response(file, {
                 headers: {
                     'Content-Type': imageInProject[0].mimeType,
                 },
             });
        }

        return c.json({ error: 'Image not found or unauthorized' }, 404);
    }

    const file = Bun.file(imageRecord[0].storagePath);
    return new Response(file, {
        headers: {
            'Content-Type': imageRecord[0].mimeType,
        },
    });
});

const patchImageRoute = createRoute({
    method: 'patch',
    path: '/{imageId}',
    summary: 'Update an image',
    description: 'Updates the `compareViewSelected` status of an image.',
    request: {
        params: z.object({
            imageId: z.uuid(),
        }),
        body: {
            content: {
                'application/json': {
                    schema: z.object({
                        compareViewSelected: z.boolean(),
                    }),
                },
            },
        },
    },
    responses: {
        200: {
            description: 'Successful response with the updated image details.',
            content: {
                'application/json': {
                    schema: ImageSchema,
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
            description: 'Image not found or unauthorized.',
            content: {
                'application/json': {
                schema: ErrorSchema,
                },
            },
        },
    },
});

app.openapi(patchImageRoute, async (c) => {
    const { imageId } = c.req.param();
    const { compareViewSelected } = c.req.valid('json');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const updatedImages = await db
        .update(imageTable)
        .set({ compareViewSelected })
        .where(and(eq(imageTable.id, imageId), eq(imageTable.userId, user.id)))
        .returning();

    if (updatedImages.length === 0) {
        return c.json({ error: 'Image not found or unauthorized' }, 404);
    }

    return c.json(updatedImages[0]);
});

const putImageSelectionRoute = createRoute({
    method: 'put',
    path: '/{imageId}/selection',
    summary: 'Update image selection',
    description: 'Updates the selection status (picked, rating) of an image.',
    request: {
        params: z.object({
            imageId: z.uuid(),
        }),
        body: {
            content: {
                'application/json': {
                    schema: z.object({
                        isPicked: z.boolean().optional(),
                        rating: z.number().int().min(0).max(5).optional(),
                    }),
                },
            },
        },
    },
    responses: {
        200: {
            description: 'Successful response confirming the update.',
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

app.openapi(putImageSelectionRoute, async (c) => {
    const { imageId } = c.req.param();
    const { isPicked, rating } = c.req.valid('json');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const id = randomUUID();
    await db
        .insert(imageSelection)
        .values({
            id,
            imageId,
            userId: user.id,
            isPicked,
            rating,
        })
        .onConflictDoUpdate({
            target: [imageSelection.imageId, imageSelection.userId],
            set: { isPicked, rating },
        });

    return c.json({ message: 'Selection updated' });
});

const postImageRejectRoute = createRoute({
    method: 'post',
    path: '/{imageId}/reject',
    summary: 'Reject an image',
    description: 'Records a user\'s rejection of an image, including the reason.',
    request: {
        params: z.object({
            imageId: z.uuid(),
        }),
        body: {
            content: {
                'application/json': {
                    schema: z.object({
                        reasonCode: z.enum(['BLURRY', 'BAD_COMPOSITION', 'CLOSED_EYES', 'DUPLICATE', 'OTHER']),
                        reasonText: z.string().optional(),
                    }),
                },
            },
        },
    },
    responses: {
        200: {
            description: 'Successful response confirming the rejection.',
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

app.openapi(postImageRejectRoute, async (c) => {
    const { imageId } = c.req.param();
    const { reasonCode, reasonText } = c.req.valid('json');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    const dbReasonCode = (
        reasonCode === 'BLURRY' ? 'out_of_focus' :
        reasonCode === 'BAD_COMPOSITION' ? 'poor_composition' :
        reasonCode === 'DUPLICATE' ? 'duplicate' :
        'other'
    ) as typeof userRejectionReason.$inferInsert['reasonCode'];

    const finalReasonText = reasonCode === 'CLOSED_EYES' 
        ? (reasonText ? `Closed eyes: ${reasonText}` : 'Closed eyes')
        : reasonText;

    const rejectionId = randomUUID();
    await db.insert(userRejectionReason).values({
        id: rejectionId,
        imageId,
        userId: user.id,
        reasonCode: dbReasonCode,
        reasonText: finalReasonText,
    });

    const selectionId = randomUUID();
    await db
        .insert(imageSelection)
        .values({
            id: selectionId,
            imageId,
            userId: user.id,
            isRejected: true,
        })
        .onConflictDoUpdate({
            target: [imageSelection.imageId, imageSelection.userId],
            set: { isRejected: true },
        });

    return c.json({ message: 'Rejection recorded' });
});

const BatchRejectRequestSchema = z.object({
  imageIds: z.array(z.uuid()),
  reasonCode: z.enum(['BLURRY', 'BAD_COMPOSITION', 'CLOSED_EYES', 'DUPLICATE', 'OTHER']),
  reasonText: z.string().optional(),
});

const BatchRejectResponseSchema = z.object({
  succeeded: z.array(z.string()),
  failed: z.array(z.object({
    imageId: z.string(),
    error: z.string(),
  })),
});
 
const postBatchImageRejectRoute = createRoute({
  method: 'post',
  path: '/batch-reject',
  summary: 'Batch reject images',
  description: 'Reject multiple images at once with a single reason.',
  request: {
    body: {
      content: {
        'application/json': {
          schema: BatchRejectRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Batch rejection results.',
      content: {
        'application/json': {
          schema: BatchRejectResponseSchema,
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

app.openapi(postBatchImageRejectRoute, async (c) => {
  const { imageIds, reasonCode, reasonText } = c.req.valid('json');
  const user = c.get('user');

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  const succeeded: string[] = [];
  const failed: { imageId: string; error: string }[] = [];

  if (imageIds.length === 0) {
      return c.json({ succeeded, failed });
  }

  const dbReasonCode = (
    reasonCode === 'BLURRY' ? 'out_of_focus' :
    reasonCode === 'BAD_COMPOSITION' ? 'poor_composition' :
    reasonCode === 'DUPLICATE' ? 'duplicate' :
    'other'
  ) as typeof userRejectionReason.$inferInsert['reasonCode'];

  const finalReasonText = reasonCode === 'CLOSED_EYES'
    ? (reasonText ? `Closed eyes: ${reasonText}` : 'Closed eyes')
    : reasonText;

  // 1. Identify valid images
  const validImages = await db
    .select({ id: imageTable.id })
    .from(imageTable)
    .leftJoin(project, eq(imageTable.projectId, project.id))
    .where(and(
        inArray(imageTable.id, imageIds),
        or(
            eq(imageTable.userId, user.id),
            and(
                eq(project.userId, user.id),
                eq(imageTable.projectId, project.id)
            )
        )
    ));

  const validImageIds = new Set(validImages.map(i => i.id));

  // 2. Separate succeeded and failed (pre-execution)
  for (const id of imageIds) {
      if (!validImageIds.has(id)) {
          failed.push({ imageId: id, error: 'Image not found or unauthorized' });
      }
  }

  const imagesToProcess = Array.from(validImageIds);

  if (imagesToProcess.length > 0) {
      try {
          // Bulk insert rejection reasons
          const rejectionValues = imagesToProcess.map(imageId => ({
              id: randomUUID(),
              imageId,
              userId: user.id,
              reasonCode: dbReasonCode,
              reasonText: finalReasonText,
          }));

          await db.insert(userRejectionReason).values(rejectionValues);

          // Bulk insert/update selections
          const selectionValues = imagesToProcess.map(imageId => ({
              id: randomUUID(), // Note: ID is only used for new rows.
              imageId,
              userId: user.id,
              isRejected: true,
          }));

          await db
            .insert(imageSelection)
            .values(selectionValues)
            .onConflictDoUpdate({
                target: [imageSelection.imageId, imageSelection.userId],
                set: { isRejected: true },
            });

           succeeded.push(...imagesToProcess);

      } catch (e) {
           console.error("Batch reject transaction failed", e);
           // If bulk operation fails, fail all valid ones with internal error.
           for (const id of imagesToProcess) {
               failed.push({ imageId: id, error: 'Internal server error' });
           }
      }
  }

  return c.json({ succeeded, failed });
});

const BatchUpdateImagesSchema = z.object({
    imageIds: z.array(z.uuid()),
    compareViewSelected: z.boolean(),
});

const postBatchUpdateImagesRoute = createRoute({
    method: 'post',
    path: '/batch-update',
    summary: 'Batch update images',
    description: 'Updates the `compareViewSelected` status for multiple images.',
    request: {
        body: {
            content: {
                'application/json': {
                    schema: BatchUpdateImagesSchema,
                },
            },
        },
    },
    responses: {
        200: {
            description: 'Batch update results.',
            content: {
                'application/json': {
                    schema: z.object({
                        updatedCount: z.number(),
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
    }
});

app.openapi(postBatchUpdateImagesRoute, async (c) => {
    const { imageIds, compareViewSelected } = c.req.valid('json');
    const user = c.get('user');

    if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    if (imageIds.length === 0) {
        return c.json({ updatedCount: 0, message: 'No images provided' }, 200);
    }

    // 1. Identify valid images (user owns image OR user owns project containing image)
    const validImages = await db
        .select({ id: imageTable.id })
        .from(imageTable)
        .leftJoin(project, eq(imageTable.projectId, project.id))
        .where(and(
            inArray(imageTable.id, imageIds),
            or(
                eq(imageTable.userId, user.id),
                and(
                    eq(project.userId, user.id),
                    eq(imageTable.projectId, project.id)
                )
            )
        ));

    const validImageIds = validImages.map(i => i.id);

    if (validImageIds.length === 0) {
        return c.json({ updatedCount: 0, message: 'No valid images found or unauthorized' }, 200);
    }

    // 2. Perform update
    await db
        .update(imageTable)
        .set({ compareViewSelected })
        .where(inArray(imageTable.id, validImageIds));

    return c.json({
        updatedCount: validImageIds.length,
        message: 'Images updated successfully'
    }, 200);
});

export default app;
