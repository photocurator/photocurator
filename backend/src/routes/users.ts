import { Hono } from 'hono';
import { db } from '../db';
import { shootingPatterns, images, imageExifs } from '../db/schema';
import { eq } from 'drizzle-orm';

const app = new Hono()
  .get(
    '/me/statistics',
    async (c) => {
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      const stats = await db
        .select()
        .from(shootingPatterns)
        .where(eq(shootingPatterns.userId, user.id));

      if (stats.length === 0) {
        return c.json({ error: 'No statistics found' }, 404);
      }

      return c.json(stats[0]);
    }
  )
  .post(
    '/me/statistics/calculate',
    async (c) => {
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      const aiServiceUrl = c.env.AI_SERVICE_URL || 'http://localhost:8001';
      const response = await fetch(`${aiServiceUrl}/statistics/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: user.id }),
      });

      const data = await response.json();

      return c.json(data, response.status);
    }
  );

export default app;
