/**
 * @module routes/users
 * This file defines the API routes for user-specific data, such as statistics.
 */
import { OpenAPIHono, createRoute } from 'hono-zod-openapi';
import { z } from 'zod';
import { db } from '../db';
import { shootingPattern } from '../db/schema';
import { eq } from 'drizzle-orm';
import { AuthType } from '../lib/auth';

type Variables = {
  user: AuthType['user'];
  session: AuthType['session'];
};

const app = new OpenAPIHono<{ Variables: Variables }>();

const ShootingPatternSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  mostUsedCameraId: z.string().nullable(),
  mostUsedLensId: z.string().nullable(),
  avgIso: z.string().nullable(),
  mostCommonAperture: z.string().nullable(),
  mostCommonFocalLength: z.string().nullable(),
  totalPhotosAnalyzed: z.number(),
  lastAnalyzedAt: z.string().datetime().nullable(),
  createdAt: z.string().datetime(),
});

const ErrorSchema = z.object({
  error: z.string(),
});

const getStatisticsRoute = createRoute({
  method: 'get',
  path: '/me/statistics',
  summary: 'Get user statistics',
  description: 'Retrieves the shooting statistics for the authenticated user.',
  responses: {
    200: {
      description: 'Successful response with the user\'s shooting statistics.',
      content: {
        'application/json': {
          schema: ShootingPatternSchema,
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
      description: 'No statistics found for the user.',
      content: {
        'application/json': {
          schema: ErrorSchema,
        },
      },
    },
  },
});

app.openapi(getStatisticsRoute, async (c) => {
  const user = c.get('user');

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  const stats = await db
    .select()
    .from(shootingPattern)
    .where(eq(shootingPattern.userId, user.id));

  if (stats.length === 0) {
    return c.json({ error: 'No statistics found' }, 404);
  }

  return c.json(stats[0]);
});

const calculateStatisticsRoute = createRoute({
    method: 'post',
    path: '/me/statistics/calculate',
    summary: 'Calculate user statistics',
    description: 'Triggers the calculation of shooting statistics for the authenticated user.',
    responses: {
        202: {
            description: 'Successful response indicating the calculation is in progress.',
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

app.openapi(calculateStatisticsRoute, async (c) => {
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

    return c.json(data, response.status as any);
});

export default app;
