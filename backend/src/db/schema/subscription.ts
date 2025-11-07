import { pgTable, text, timestamp, boolean, bigint } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { subscriptionTierEnum } from "./enums";
import { user } from "./auth";

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
export const subscriptionRelations = relations(subscription, ({ one }) => ({
  user: one(user, {
    fields: [subscription.userId],
    references: [user.id],
  }),
}));

export const userStorageQuotaRelations = relations(userStorageQuota, ({ one }) => ({
  user: one(user, {
    fields: [userStorageQuota.userId],
    references: [user.id],
  }),
}));
