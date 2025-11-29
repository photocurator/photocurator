/**
 * @module db/schema/advertisement
 * This file defines the database schema for advertisements, including targeting rules and impressions.
 */
import { pgTable, text, timestamp, boolean, integer, decimal } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { adTypeEnum, userSegmentEnum } from "./enums";
import { user } from "./auth";
import { project } from "./project";

/**
 * The `advertisement` table stores information about advertisements.
 */
export const advertisement = pgTable("advertisement", {
  id: text("id").primaryKey(),
  adType: adTypeEnum("ad_type").notNull(),
  productName: text("product_name").notNull(),
  productDescription: text("product_description"),
  productImageUrl: text("product_image_url"),
  affiliateUrl: text("affiliate_url").notNull(),
  isActive: boolean("is_active").default(true).notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
  expiresAt: timestamp("expires_at"),
});

/**
 * The `ad_targeting_rule` table stores the rules for targeting advertisements to users.
 */
export const adTargetingRule = pgTable("ad_targeting_rule", {
  id: text("id").primaryKey(),
  adId: text("ad_id")
    .notNull()
    .references(() => advertisement.id, { onDelete: "cascade" }),
  cameraModel: text("camera_model"),
  lensModel: text("lens_model"),
  userSegment: userSegmentEnum("user_segment"),
  minIsoUsage: integer("min_iso_usage"),
  maxIsoUsage: integer("max_iso_usage"),
  minFocalLength: decimal("min_focal_length", { precision: 10, scale: 2 }),
  maxFocalLength: decimal("max_focal_length", { precision: 10, scale: 2 }),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

/**
 * The `ad_impression` table tracks when an advertisement has been shown to a user.
 */
export const adImpression = pgTable("ad_impression", {
  id: text("id").primaryKey(),
  adId: text("ad_id")
    .notNull()
    .references(() => advertisement.id, { onDelete: "cascade" }),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  projectId: text("project_id")
    .references(() => project.id, { onDelete: "cascade" }),
  clicked: boolean("clicked").default(false).notNull(),
  clickedAt: timestamp("clicked_at"),
  impressionDate: timestamp("impression_date")
    .$defaultFn(() => new Date())
    .notNull(),
});

// Relations
/**
 * Defines the relations for the `advertisement` table.
 */
export const advertisementRelations = relations(advertisement, ({ many }) => ({
  targetingRules: many(adTargetingRule),
  impressions: many(adImpression),
}));

/**
 * Defines the relations for the `ad_targeting_rule` table.
 */
export const adTargetingRuleRelations = relations(adTargetingRule, ({ one }) => ({
  ad: one(advertisement, {
    fields: [adTargetingRule.adId],
    references: [advertisement.id],
  }),
}));

/**
 * Defines the relations for the `ad_impression` table.
 */
export const adImpressionRelations = relations(adImpression, ({ one }) => ({
  ad: one(advertisement, {
    fields: [adImpression.adId],
    references: [advertisement.id],
  }),
  user: one(user, {
    fields: [adImpression.userId],
    references: [user.id],
  }),
  project: one(project, {
    fields: [adImpression.projectId],
    references: [project.id],
  }),
}));
