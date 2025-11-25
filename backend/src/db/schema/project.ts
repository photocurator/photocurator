/**
 * @module db/schema/project
 * This file defines the database schema for projects and their associated tags.
 */
import { pgTable, text, timestamp, boolean } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { user } from "./auth";

/**
 * The `project` table stores information about user projects.
 */
export const project = pgTable("project", {
  id: text("id").primaryKey(),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  projectName: text("project_name").notNull(),
  description: text("description"),
  coverImageId: text("cover_image_id"),
  isArchived: boolean("is_archived").default(false).notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
  archivedAt: timestamp("archived_at"),
});

/**
 * The `project_tag` table stores tags associated with projects.
 */
export const projectTag = pgTable("project_tag", {
  id: text("id").primaryKey(),
  projectId: text("project_id")
    .notNull()
    .references(() => project.id, { onDelete: "cascade" }),
  tagName: text("tag_name").notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

// Relations
/**
 * Defines the relations for the `project` table.
 */
export const projectRelations = relations(project, ({ one, many }) => ({
  user: one(user, {
    fields: [project.userId],
    references: [user.id],
  }),
  tags: many(projectTag),
}));

/**
 * Defines the relations for the `project_tag` table.
 */
export const projectTagRelations = relations(projectTag, ({ one }) => ({
  project: one(project, {
    fields: [projectTag.projectId],
    references: [project.id],
  }),
}));
