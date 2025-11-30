/**
 * @module db/schema/analysis
 * This file defines the database schema for storing image analysis results,
 * including quality scores, object tags, captions, and user feedback.
 */
import { pgTable, text, timestamp, decimal, integer } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { image } from "./image";
import { imageGroup } from "./imageGroup";
import { rejectionReasonEnum } from "./enums";
import { user } from "./auth";

/**
 * The `quality_score` table stores various quality metrics for an image.
 */
export const qualityScore = pgTable("quality_score", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" })
    .unique(),
  brisqueScore: decimal("brisque_score", { precision: 10, scale: 4 }),
  tenegradScore: decimal("tenegrad_score", { precision: 10, scale: 4 }),
  musiqScore: decimal("musiq_score", { precision: 10, scale: 4 }),
  modelVersion: text("model_version").notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

/**
 * The `best_shot_recommendation` table stores recommendations for the best image within a group.
 */
export const bestShotRecommendation = pgTable("best_shot_recommendation", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  groupId: text("group_id")
    .notNull()
    .references(() => imageGroup.id, { onDelete: "cascade" }),
  modelVersion: text("model_version").notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

/**
 * The `object_tag` table stores information about objects detected in an image.
 */
export const objectTag = pgTable("object_tag", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  tagName: text("tag_name").notNull(),
  tagCategory: text("tag_category"),
  confidence: decimal("confidence", { precision: 5, scale: 4 }),
  boundingBoxX: integer("bounding_box_x"),
  boundingBoxY: integer("bounding_box_y"),
  boundingBoxWidth: integer("bounding_box_width"),
  boundingBoxHeight: integer("bounding_box_height"),
  modelVersion: text("model_version").notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

/**
 * The `image_caption` table stores captions generated for an image.
 */
export const imageCaption = pgTable("image_caption", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  caption: text("caption").notNull(),
  modelVersion: text("model_version").notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

/**
 * The `user_rejection_reason` table stores the reasons why a user rejected an image.
 */
export const userRejectionReason = pgTable("user_rejection_reason", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  reasonCode: rejectionReasonEnum("reason_code").notNull(),
  reasonText: text("reason_text"),
  rejectedAt: timestamp("rejected_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

// Relations
/**
 * Defines the relations for the `quality_score` table.
 */
export const qualityScoreRelations = relations(qualityScore, ({ one }) => ({
  image: one(image, {
    fields: [qualityScore.imageId],
    references: [image.id],
  }),
}));

/**
 * Defines the relations for the `best_shot_recommendation` table.
 */
export const bestShotRecommendationRelations = relations(bestShotRecommendation, ({ one }) => ({
  image: one(image, {
    fields: [bestShotRecommendation.imageId],
    references: [image.id],
  }),
  group: one(imageGroup, {
    fields: [bestShotRecommendation.groupId],
    references: [imageGroup.id],
  }),
}));

/**
 * Defines the relations for the `object_tag` table.
 */
export const objectTagRelations = relations(objectTag, ({ one }) => ({
  image: one(image, {
    fields: [objectTag.imageId],
    references: [image.id],
  }),
}));

/**
 * Defines the relations for the `user_rejection_reason` table.
 */
export const userRejectionReasonRelations = relations(userRejectionReason, ({ one }) => ({
  image: one(image, {
    fields: [userRejectionReason.imageId],
    references: [image.id],
  }),
  user: one(user, {
    fields: [userRejectionReason.userId],
    references: [user.id],
  }),
}));

/**
 * Defines the relations for the `image_caption` table.
 */
export const imageCaptionRelations = relations(imageCaption, ({ one }) => ({
  image: one(image, {
    fields: [imageCaption.imageId],
    references: [image.id],
  }),
}));
