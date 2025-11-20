import { Hono } from 'hono';
import { db } from '../db';
import { projects, images, qualityScores, imageSelections, objectTags, analysisJobs, analysisJobItems } from '../db/schema';
import { eq, and, gt, desc, inArray } from 'drizzle-orm';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { mkdir, writeFile } from 'fs/promises';
import { v4 as uuidv4 } from 'uuid';

const app = new Hono()
  .get(
    '/',
    async (c) => {
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      const projectList = await db
        .select()
        .from(projects)
        .where(eq(projects.userId, user.id));

      return c.json(projectList);
    }
  )
  .post(
    '/',
    zValidator(
      'json',
      z.object({
        name: z.string().max(100),
        description: z.string().optional(),
      })
    ),
    async (c) => {
      const { name, description } = c.req.valid('json');
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      const newProject = await db
        .insert(projects)
        .values({
          projectName: name,
          description,
          userId: user.id,
        })
        .returning();

      return c.json(newProject[0], 201);
    }
  )
  .get(
    '/:projectId/images',
    zValidator(
      'query',
      z.object({
        viewType: z.enum(['ALL', 'PICKED', 'TRASH', 'BEST_SHOTS']).default('ALL'),
        minQualityScore: z.coerce.number().optional(),
        nextCursor: z.string().optional(),
      })
    ),
    async (c) => {
      const { projectId } = c.req.param();
      const { viewType, minQualityScore, nextCursor } = c.req.valid('query');
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      let query = db
        .select({
          image: images,
          qualityScore: qualityScores,
          imageSelection: imageSelections,
        })
        .from(images)
        .where(eq(images.projectId, projectId))
        .leftJoin(qualityScores, eq(qualityScores.imageId, images.id))
        .leftJoin(imageSelections, eq(imageSelections.imageId, images.id));

      if (viewType === 'PICKED') {
        query = query.where(eq(imageSelections.isPicked, true));
      } else if (viewType === 'TRASH') {
        query = query.where(eq(imageSelections.isRejected, true));
      } else if (viewType === 'BEST_SHOTS') {
        query = query.orderBy(desc(qualityScores.musiqScore));
      }

      if (minQualityScore) {
        query = query.where(gt(qualityScores.musiqScore, minQualityScore));
      }

      const limit = 20;
      if (nextCursor) {
        query = query.where(gt(images.id, nextCursor));
      }
      query = query.limit(limit);

      const imageList = await query;

      if (imageList.length === 0) {
        return c.json({ data: [], nextCursor: null });
      }

      const imageIds = imageList.map(i => i.image.id);
      const tags = await db
        .select()
        .from(objectTags)
        .where(inArray(objectTags.imageId, imageIds));

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
    }
  )
  .post(
    '/:projectId/images',
    async (c) => {
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

        await db.insert(images).values({
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
    }
  )
  .post(
    '/:projectId/analyze',
    zValidator(
      'json',
      z.object({
        jobType: z.enum(['FULL_SCAN', 'OBJECT_DETECTION_ONLY', 'SCORING_ONLY']).default('FULL_SCAN'),
      })
    ),
    async (c) => {
      const { projectId } = c.req.param();
      const { jobType } = c.req.valid('json');
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      const newJob = await db.insert(analysisJobs).values({
        projectId,
        userId: user.id,
        jobType,
      }).returning();

      const imagesToAnalyze = await db.select().from(images).where(eq(images.projectId, projectId));

      const jobItems = [];
      for (const image of imagesToAnalyze) {
        const newJobItem = await db.insert(analysisJobItems).values({
          jobId: newJob[0].id,
          imageId: image.id,
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
    }
  )
  .get(
    '/:projectId/analysis/status',
    async (c) => {
      const { projectId } = c.req.param();
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      const latestJob = await db
        .select()
        .from(analysisJobs)
        .where(and(eq(analysisJobs.projectId, projectId), eq(analysisJobs.userId, user.id)))
        .orderBy(desc(analysisJobs.createdAt))
        .limit(1);

      if (latestJob.length === 0) {
        return c.json({ error: 'No analysis job found' }, 404);
      }

      const jobItems = await db
        .select()
        .from(analysisJobItems)
        .where(eq(analysisJobItems.jobId, latestJob[0].id));

      const completedItems = jobItems.filter(item => item.status === 'completed').length;
      const totalItems = jobItems.length;
      const progressPercentage = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;

      return c.json({
        jobId: latestJob[0].id,
        status: latestJob[0].status,
        progressPercentage,
        completedItems,
        totalItems,
      });
    }
  );

export default app;
