import { pgTable, text, timestamp, integer, decimal } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { searchTypeEnum } from "./enums";
import { user } from "./auth";

export const userSearch = pgTable("user_search", {
  id: text("id").primaryKey(),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  searchQuery: text("search_query").notNull(),
  searchType: searchTypeEnum("search_type").notNull(),
  resultsCount: integer("results_count").notNull(),
  searchDurationMs: integer("search_duration_ms"),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

export const shootingPattern = pgTable("shooting_pattern", {
  id: text("id").primaryKey(),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  mostUsedCameraId: text("most_used_camera_id"),
  mostUsedLensId: text("most_used_lens_id"),
  avgIso: decimal("avg_iso", { precision: 10, scale: 2 }),
  mostCommonAperture: decimal("most_common_aperture", { precision: 10, scale: 2 }),
  mostCommonFocalLength: decimal("most_common_focal_length", { precision: 10, scale: 2 }),
  totalPhotosAnalyzed: integer("total_photos_analyzed").default(0).notNull(),
  lastAnalyzedAt: timestamp("last_analyzed_at"),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

// Relations
export const userSearchRelations = relations(userSearch, ({ one }) => ({
  user: one(user, {
    fields: [userSearch.userId],
    references: [user.id],
  }),
}));

export const shootingPatternRelations = relations(shootingPattern, ({ one }) => ({
  user: one(user, {
    fields: [shootingPattern.userId],
    references: [user.id],
  }),
}));
