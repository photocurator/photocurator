import { Hono } from 'hono';
import { db } from '../db';
import { imageSelections, userRejectionReasons } from '../db/schema';
import { eq, and } from 'drizzle-orm';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';

const app = new Hono()
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
