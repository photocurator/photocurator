import { pgTable, text, timestamp, integer } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { jobTypeEnum, jobStatusEnum, itemStatusEnum } from "./enums";
import { project } from "./project";
import { user } from "./auth";
import { image } from "./image";

export const analysisJob = pgTable("analysis_job", {
  id: text("id").primaryKey(),
  projectId: text("project_id")
    .notNull()
    .references(() => project.id, { onDelete: "cascade" }),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  jobType: jobTypeEnum("job_type").notNull(),
  jobStatus: jobStatusEnum("job_status").default("pending").notNull(),
  errorMessage: text("error_message"),
  startedAt: timestamp("started_at"),
  completedAt: timestamp("completed_at"),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
});

export const analysisJobItem = pgTable("analysis_job_item", {
  id: text("id").primaryKey(),
  jobId: text("job_id")
    .notNull()
    .references(() => analysisJob.id, { onDelete: "cascade" }),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  itemStatus: itemStatusEnum("item_status").default("pending").notNull(),
  errorMessage: text("error_message"),
  processingTimeMs: integer("processing_time_ms"),
  retryCount: integer("retry_count").default(0).notNull(),
  startedAt: timestamp("started_at"),
  completedAt: timestamp("completed_at"),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

// Relations
export const analysisJobRelations = relations(analysisJob, ({ one, many }) => ({
  project: one(project, {
    fields: [analysisJob.projectId],
    references: [project.id],
  }),
  user: one(user, {
    fields: [analysisJob.userId],
    references: [user.id],
  }),
  items: many(analysisJobItem),
}));

export const analysisJobItemRelations = relations(analysisJobItem, ({ one }) => ({
  job: one(analysisJob, {
    fields: [analysisJobItem.jobId],
    references: [analysisJob.id],
  }),
  image: one(image, {
    fields: [analysisJobItem.imageId],
    references: [image.id],
  }),
}));
