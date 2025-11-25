/**
 * @module routes/ads
 * This file defines the API routes for serving advertisements.
 */
import { OpenAPIHono, createRoute } from 'hono-zod-openapi';
import { z } from 'zod';
import { db } from '../db';
import { adTargetingRule, advertisement, shootingPattern } from '../db/schema';
import { eq, and, or, gte, lte } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { AuthType } from '../lib/auth';

type Variables = {
  user: AuthType['user'];
  session: AuthType['session'];
};

const app = new OpenAPIHono<{ Variables: Variables }>();

const BannerAdSchema = z.object({
  adId: z.string().uuid().openapi({
    description: 'The ID of the advertisement.',
    example: '123e4567-e89b-12d3-a456-426614174000',
  }),
  imageUrl: z.string().url().openapi({
    description: 'The URL of the ad image.',
    example: 'https://example.com/ad.png',
  }),
  clickUrl: z.string().url().openapi({
    description: 'The affiliate URL to redirect to when the ad is clicked.',
    example: 'https://example.com/product/123',
  }),
  trackingToken: z.string().uuid().openapi({
    description: 'A token for tracking ad impressions and clicks.',
    example: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
  }),
});

const ErrorSchema = z.object({
  error: z.string(),
});

const route = createRoute({
  method: 'get',
  path: '/banner',
  summary: 'Request a targeted ad',
  description: 'Retrieves the most suitable ad for the user based on their shooting pattern.',
  responses: {
    200: {
      description: 'Successful response with an ad banner.',
      content: {
        'application/json': {
          schema: BannerAdSchema,
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
      description: 'No suitable ad or user pattern found.',
      content: {
        'application/json': {
          schema: ErrorSchema,
        },
      },
    },
  },
});

app.openapi(route, async (c) => {
  const user = c.get('user');

  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  const userPattern = await db
    .select()
    .from(shootingPattern)
    .where(eq(shootingPattern.userId, user.id));

  if (userPattern.length === 0) {
    return c.json({ error: 'No user pattern found' }, 404);
  }

  const pattern = userPattern[0];

  const result = await db
    .select()
    .from(advertisement)
    .leftJoin(adTargetingRule, eq(adTargetingRule.adId, advertisement.id))
    .where(
      or(
        eq(adTargetingRule.id, null), // General ad
        and(
          gte(pattern.avgIso, adTargetingRule.minIsoUsage),
          lte(pattern.avgIso, adTargetingRule.maxIsoUsage),
          eq(pattern.mostCommonFocalLength, adTargetingRule.maxFocalLength)
        )
      )
    )
    .limit(1);

  if (result.length === 0) {
    return c.json({ error: 'No suitable ad found' }, 404);
  }

  const selectedAd = result[0].advertisement;

  return c.json({
    adId: selectedAd.id,
    imageUrl: selectedAd.productImageUrl,
    clickUrl: selectedAd.affiliateUrl,
    trackingToken: uuidv4(),
  });
});

export default app;
