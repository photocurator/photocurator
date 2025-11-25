/**
 * @module db/schema/imageGroup
 * This file defines the database schema for image groups and their memberships.
 */
import { pgTable, text, timestamp, decimal, integer } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { groupTypeEnum } from "./enums";
import { project } from "./project";
import { image } from "./image";

/**
 * The `image_group` table stores information about groups of images.
 */
export const imageGroup = pgTable("image_group", {
  id: text("id").primaryKey(),
  projectId: text("project_id")
    .notNull()
    .references(() => project.id, { onDelete: "cascade" }),
  groupType: groupTypeEnum("group_type").notNull(),
  representativeImageId: text("representative_image_id"),
  timeRangeStart: timestamp("time_range_start"),
  timeRangeEnd: timestamp("time_range_end"),
  similarityScore: decimal("similarity_score", { precision: 5, scale: 4 }),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
});

/**
 * The `image_group_membership` table links images to image groups, defining which images belong to which groups.
 */
export const imageGroupMembership = pgTable("image_group_membership", {
  id: text("id").primaryKey(),
  groupId: text("group_id")
    .notNull()
    .references(() => imageGroup.id, { onDelete: "cascade" }),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  sequenceOrder: integer("sequence_order"),
  addedAt: timestamp("added_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

// Relations
/**
 * Defines the relations for the `image_group` table.
 */
export const imageGroupRelations = relations(imageGroup, ({ one, many }) => ({
  project: one(project, {
    fields: [imageGroup.projectId],
    references: [project.id],
  }),
  memberships: many(imageGroupMembership),
}));

/**
 * Defines the relations for the `image_group_membership` table.
 */
export const imageGroupMembershipRelations = relations(imageGroupMembership, ({ one }) => ({
  group: one(imageGroup, {
    fields: [imageGroupMembership.groupId],
    references: [imageGroup.id],
  }),
  image: one(image, {
    fields: [imageGroupMembership.imageId],
    references: [image.id],
  }),
}));
