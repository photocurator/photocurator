/**
 * @module routes/images
 * This file defines the API routes for managing and retrieving images.
 */
import { OpenAPIHono, createRoute } from 'hono-zod-openapi';
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
} from '../db/schema';
import { eq, and, or, ilike, gt, desc, asc, sql, exists, inArray, SQL } from 'drizzle-orm';
import { AuthType } from '../lib/auth';

type Variables = {
  user: AuthType['user'];
  session: AuthType['session'];
};

const app = new OpenAPIHono<{ Variables: Variables }>();

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
      }, {} as Record<string, typeof objectTag.$inferSelect[]>);

      const responseData = imageList.map((i) => ({
        ...i,
        objectTags: tagsByImageId[i.image.id] || [],
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

const patchImageRoute = createRoute({
    method: 'patch',
    path: '/{imageId}',
    summary: 'Update an image',
    description: 'Updates the `compareViewSelected` status of an image.',
    request: {
        params: z.object({
            imageId: z.string().uuid(),
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
            imageId: z.string().uuid(),
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

    await db
        .insert(imageSelection)
        .values({
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
            imageId: z.string().uuid(),
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

    await db.insert(userRejectionReason).values({
        imageId,
        userId: user.id,
        reasonCode,
        reasonText,
    });

    await db
        .insert(imageSelection)
        .values({
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

export default app;
