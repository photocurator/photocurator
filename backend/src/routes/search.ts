/**
 * @module routes/search
 * This file defines the API routes for searching images based on various criteria.
 */
import { OpenAPIHono, createRoute } from '@hono/zod-openapi';
import { z } from 'zod';
import { db } from '../db';
import {
  image as imageTable,
  imageSelection,
  qualityScore,
  imageCaption,
  objectTag,
  project,
  imageGroupMembership,
} from '../db/schema';
import { eq, and, or, ilike, gt, gte, lte, desc, asc, exists, inArray, SQL, not, sql } from 'drizzle-orm';
import { AuthType } from '../lib/auth';

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
});

const ErrorSchema = z.object({
  error: z.string(),
});

const searchImagesRoute = createRoute({
  method: 'get',
  path: '/',
  summary: 'Search images',
  description: 'Search images based on various criteria including project, object, caption, score, time, and selection status.',
  request: {
    query: z.object({
      projectId: z.string().uuid().optional(),
      detectedObject: z.string().optional(),
      caption: z.string().optional(),
      isPicked: z.enum(['true', 'false']).optional(),
      isRejected: z.enum(['true', 'false']).optional(),
      minMusiqScore: z.coerce.number().optional(),
      uploadTimeStart: z.string().datetime().optional(),
      uploadTimeEnd: z.string().datetime().optional(),
      captureTimeStart: z.string().datetime().optional(),
      captureTimeEnd: z.string().datetime().optional(),
      sort: z.enum(['musiqScore', 'captureTime']).optional(),
      order: z.enum(['asc', 'desc']).default('desc'),
      page: z.coerce.number().min(1).default(1),
      limit: z.coerce.number().min(1).max(100).default(20),
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
            total: z.number().optional(),
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

app.openapi(searchImagesRoute, async (c) => {
  const {
    projectId,
    detectedObject,
    caption,
    isPicked,
    isRejected,
    minMusiqScore,
    uploadTimeStart,
    uploadTimeEnd,
    captureTimeStart,
    captureTimeEnd,
    sort,
    order,
    page,
    limit,
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

  if (projectId) {
    filters.push(eq(imageTable.projectId, projectId));
  }

  if (detectedObject) {
    const objects = detectedObject.split(',');
    const tagExists = exists(
      db
        .select()
        .from(objectTag)
        .where(
          and(
            eq(objectTag.imageId, imageTable.id),
            inArray(objectTag.tagName, objects) // Exact match as requested
          )
        )
    );
    filters.push(tagExists);
  }

  if (caption) {
    const captionPattern = `%${caption}%`;
    const captionExists = exists(
      db
        .select()
        .from(imageCaption)
        .where(
          and(
            eq(imageCaption.imageId, imageTable.id),
            ilike(imageCaption.caption, captionPattern) // Full text search
          )
        )
    );
    filters.push(captionExists);
  }

  if (isPicked) {
    const isPickedBool = isPicked === 'true';
    // If filtering by picked, we assume they must have a selection record
    filters.push(eq(imageSelection.isPicked, isPickedBool));
  }

  if (isRejected) {
    const isRejectedBool = isRejected === 'true';
    if (isRejectedBool) {
      filters.push(eq(imageSelection.isRejected, true));
    } else {
        // "is not rejected" means is_rejected is false OR no selection record exists
        filters.push(
            or(
                eq(imageSelection.isRejected, false),
                not(exists(
                    db.select()
                    .from(imageSelection)
                    .where(
                        and(
                            eq(imageSelection.imageId, imageTable.id),
                            eq(imageSelection.userId, user.id)
                        )
                    )
                ))
            )
        )
    }
  }

  if (minMusiqScore !== undefined) {
    filters.push(gt(qualityScore.musiqScore, minMusiqScore.toString()));
  }

  if (uploadTimeStart) {
    filters.push(gte(imageTable.uploadDatetime, new Date(uploadTimeStart)));
  }

  if (uploadTimeEnd) {
    filters.push(lte(imageTable.uploadDatetime, new Date(uploadTimeEnd)));
  }

  if (captureTimeStart) {
    filters.push(gte(imageTable.captureDatetime, new Date(captureTimeStart)));
  }

  if (captureTimeEnd) {
    filters.push(lte(imageTable.captureDatetime, new Date(captureTimeEnd)));
  }

  const validFilters = filters.filter((f): f is SQL => f !== undefined);

  // ---- COUNT TOTAL ----
  // Build the count query with the exact same filters (no limit/offset)
  const total = await db
    .select({ count: sql<number>`count(*)::int` })
    .from(imageTable)
    .leftJoin(project, eq(imageTable.projectId, project.id))
    .leftJoin(imageSelection, and(eq(imageSelection.imageId, imageTable.id), eq(imageSelection.userId, user.id)))
    .leftJoin(qualityScore, eq(qualityScore.imageId, imageTable.id))
    .where(validFilters.length > 0 ? and(...validFilters) : undefined)
    .then(rows => rows[0]?.count || 0);

  // ---- PAGINATE ACTUAL DATA ----
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

  if (validFilters.length > 0) {
    query.where(and(...validFilters));
  }

  let orderByClause: SQL = desc(imageTable.createdAt); // Default

  if (sort === 'musiqScore') {
    const direction = order === 'asc' ? asc : desc;
    orderByClause = direction(qualityScore.musiqScore);
  } else if (sort === 'captureTime') {
     const direction = order === 'asc' ? asc : desc;
     orderByClause = direction(imageTable.captureDatetime);
  } else {
     // Fallback or default
     orderByClause = desc(qualityScore.musiqScore);
  }

  query.orderBy(orderByClause);
  query.limit(limit).offset(offset);

  const imageList = await query;

  let responseData: any[] = [];
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

    responseData = imageList.map((i) => ({
      ...i,
      objectTags: tagsByImageId[i.image.id] || [],
    }));
  }

  return c.json({
    data: responseData,
    page,
    limit,
    total,
  });
});

export default app;
