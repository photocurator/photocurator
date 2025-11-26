/**
 * @module db/schema/subscription
 * This file defines the database schema for user subscriptions and storage quotas.
 */
import { pgTable, text, timestamp, boolean, bigint } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { subscriptionTierEnum } from "./enums";
import { user } from "./auth";

/**
 * The `subscription` table stores information about user subscriptions.
 */
export const subscription = pgTable("subscription", {
  id: text("id").primaryKey(),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  tier: subscriptionTierEnum("tier").notNull(),
  startDate: timestamp("start_date").notNull(),
  endDate: timestamp("end_date"),
  isActive: boolean("is_active").default(true).notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
});

/**
 * The `user_storage_quota` table stores the storage limits for each user.
 */
export const userStorageQuota = pgTable("user_storage_quota", {
  id: text("id").primaryKey(),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  limitBytes: bigint("limit_bytes", { mode: "number" }).notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
});

// Relations
/**
 * Defines the relations for the `subscription` table.
 */
export const subscriptionRelations = relations(subscription, ({ one }) => ({
  user: one(user, {
    fields: [subscription.userId],
    references: [user.id],
  }),
}));

/**
 * Defines the relations for the `user_storage_quota` table.
 */
export const userStorageQuotaRelations = relations(userStorageQuota, ({ one }) => ({
  user: one(user, {
    fields: [userStorageQuota.userId],
    references: [user.id],
  }),
}));
