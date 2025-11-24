import { Hono } from 'hono';
import { db } from '../db';
import {
  images,
  imageSelections,
  userRejectionReasons,
  imageGroupMembership,
  imageGroup,
  projects,
  qualityScores,
  imageCaption,
  objectTag,
} from '../db/schema';
import { eq, and, or, ilike, gt, lt, desc, asc, sql, exists, inArray, SQL, isNull } from 'drizzle-orm';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';

const app = new Hono()
  .get(
    '/',
    zValidator(
      'query',
      z.object({
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
      })
    ),
    async (c) => {
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
      // Allow explicit user ownership OR project ownership (for legacy images)
      filters.push(
        or(
          eq(images.userId, user.id),
          and(
            eq(projects.userId, user.id),
            eq(images.projectId, projects.id)
          )
        )
      );

      // Optional filters
      if (projectId) {
        filters.push(eq(images.projectId, projectId));
      }

      if (groupId) {
        // Use exists subquery to avoid joining and row multiplication
        const groupExists = exists(
            db.select()
            .from(imageGroupMembership)
            .where(and(
                eq(imageGroupMembership.imageId, images.id),
                eq(imageGroupMembership.groupId, groupId)
            ))
        );
        filters.push(groupExists);
      }

      if (isPicked) {
        const isPickedBool = isPicked === 'true';
        filters.push(eq(imageSelections.isPicked, isPickedBool));
      }

      if (isRejected) {
        const isRejectedBool = isRejected === 'true';
        filters.push(eq(imageSelections.isRejected, isRejectedBool));
      }

      if (rating !== undefined) {
        filters.push(eq(imageSelections.rating, rating));
      }

      if (minQualityScore !== undefined) {
        filters.push(gt(qualityScores.musiqScore, minQualityScore.toString()));
      }

      if (q) {
        const searchPattern = `%${q}%`;
        const captionExists = exists(
          db
            .select()
            .from(imageCaption)
            .where(
              and(
                eq(imageCaption.imageId, images.id),
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
                eq(objectTag.imageId, images.id),
                ilike(objectTag.tagName, searchPattern)
              )
            )
        );

        filters.push(or(captionExists, tagExists));
      }

      // Initialize query with necessary joins that don't change based on input (or are handled by subqueries)
      // We join projects to allow the ownership check for legacy images
      // We join imageSelections and qualityScores for filtering/sorting as requested
      const query = db
        .select({
          image: images,
          qualityScore: qualityScores,
          imageSelection: imageSelections,
        })
        .from(images)
        .leftJoin(projects, eq(images.projectId, projects.id))
        .leftJoin(imageSelections, and(eq(imageSelections.imageId, images.id), eq(imageSelections.userId, user.id)))
        .leftJoin(qualityScores, eq(qualityScores.imageId, images.id));

      // Apply all accumulated filters
      const validFilters = filters.filter((f): f is SQL => f !== undefined);
      if (validFilters.length > 0) {
        query.where(and(...validFilters));
      }

      // Sorting
      let orderByClause = desc(images.createdAt); // Default
      if (sort) {
        const direction = order === 'asc' ? asc : desc;
        switch (sort) {
          case 'uploadDate':
            orderByClause = direction(images.uploadDatetime);
            break;
          case 'captureDate':
            orderByClause = direction(images.captureDatetime);
            break;
          case 'rating':
            orderByClause = direction(imageSelections.rating);
            break;
          case 'score':
          case 'qualityScore':
            orderByClause = direction(qualityScores.musiqScore);
            break;
          case 'createdAt':
            orderByClause = direction(images.createdAt);
            break;
        }
      }
      query.orderBy(orderByClause);

      // Pagination
      query.limit(limit).offset(offset);

      const imageList = await query;

      // Fetch tags for the result set
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
    }
  )
  .patch(
    '/:imageId',
    zValidator(
      'json',
      z.object({
        compareViewSelected: z.boolean(),
      })
    ),
    async (c) => {
      const { imageId } = c.req.param();
      const { compareViewSelected } = c.req.valid('json');
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      const updatedImages = await db
        .update(images)
        .set({ compareViewSelected })
        .where(and(eq(images.id, imageId), eq(images.userId, user.id)))
        .returning();

      if (updatedImages.length === 0) {
        return c.json({ error: 'Image not found or unauthorized' }, 404);
      }

      return c.json(updatedImages[0]);
    }
  )
  .put(
    '/:imageId/selection',
    zValidator(
      'json',
      z.object({
        isPicked: z.boolean().optional(),
        rating: z.number().int().min(0).max(5).optional(),
      })
    ),
    async (c) => {
      const { imageId } = c.req.param();
      const { isPicked, rating } = c.req.valid('json');
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      await db
        .insert(imageSelections)
        .values({
          imageId,
          userId: user.id,
          isPicked,
          rating,
        })
        .onConflictDoUpdate({
          target: [imageSelections.imageId, imageSelections.userId],
          set: { isPicked, rating },
        });

      return c.json({ message: 'Selection updated' });
    }
  )
  .post(
    '/:imageId/reject',
    zValidator(
      'json',
      z.object({
        reasonCode: z.enum(['BLURRY', 'BAD_COMPOSITION', 'CLOSED_EYES', 'DUPLICATE', 'OTHER']),
        reasonText: z.string().optional(),
      })
    ),
    async (c) => {
      const { imageId } = c.req.param();
      const { reasonCode, reasonText } = c.req.valid('json');
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      await db.insert(userRejectionReasons).values({
        imageId,
        userId: user.id,
        reasonCode,
        reasonText,
      });

      await db
        .insert(imageSelections)
        .values({
          imageId,
          userId: user.id,
          isRejected: true,
        })
        .onConflictDoUpdate({
          target: [imageSelections.imageId, imageSelections.userId],
          set: { isRejected: true },
        });

      return c.json({ message: 'Rejection recorded' });
    }
  );

export default app;
