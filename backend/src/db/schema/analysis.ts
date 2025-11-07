import { pgTable, text, timestamp, decimal, integer } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { image } from "./image";
import { imageGroup } from "./imageGroup";
import { rejectionReasonEnum } from "./enums";
import { user } from "./auth";

export const qualityScore = pgTable("quality_score", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
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
export const qualityScoreRelations = relations(qualityScore, ({ one }) => ({
  image: one(image, {
    fields: [qualityScore.imageId],
    references: [image.id],
  }),
}));

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

export const objectTagRelations = relations(objectTag, ({ one }) => ({
  image: one(image, {
    fields: [objectTag.imageId],
    references: [image.id],
  }),
}));

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
