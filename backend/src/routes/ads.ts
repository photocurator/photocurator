import { Hono } from 'hono';
import { db } from '../db';
import { adTargetingRules, advertisements, shootingPatterns } from '../db/schema';
import { eq, and, or, gte, lte } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

const app = new Hono()
  .get(
    '/banner',
    async (c) => {
      const user = c.get('user');

      if (!user) {
        return c.json({ error: 'Unauthorized' }, 401);
      }

      const userPattern = await db
        .select()
        .from(shootingPatterns)
        .where(eq(shootingPatterns.userId, user.id));

      if (userPattern.length === 0) {
        return c.json({ error: 'No user pattern found' }, 404);
      }

      const pattern = userPattern[0];

      const query = db
        .select()
        .from(advertisements)
        .leftJoin(adTargetingRules, eq(adTargetingRules.adId, advertisements.id))
        .where(
          or(
            eq(adTargetingRules.id, null), // General ad
            and(
              gte(pattern.avgIso, adTargetingRules.minIsoUsage),
              lte(pattern.avgIso, adTargetingRules.maxIsoUsage),
              eq(pattern.mostCommonFocalLength, adTargetingRules.mostCommonFocalLength)
            )
          )
        )
        .limit(1);

      const result = await query;

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
    }
  );

export default app;
