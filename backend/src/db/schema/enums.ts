import { pgEnum } from "drizzle-orm/pg-core";

export const subscriptionTierEnum = pgEnum("subscription_tier", ["free", "basic", "premium", "professional"]);
export const groupTypeEnum = pgEnum("group_type", ["similar", "burst", "sequence", "time_based"]);
export const jobTypeEnum = pgEnum("job_type", ["quality_analysis", "object_detection", "similarity_grouping", "best_shot_recommendation"]);
export const jobStatusEnum = pgEnum("job_status", ["pending", "processing", "completed", "failed", "cancelled"]);
export const itemStatusEnum = pgEnum("item_status", ["pending", "processing", "completed", "failed", "skipped"]);
export const searchTypeEnum = pgEnum("search_type", ["text", "metadata", "visual", "semantic"]);
export const adTypeEnum = pgEnum("ad_type", ["camera", "lens", "accessory", "software", "service"]);
export const userSegmentEnum = pgEnum("user_segment", ["beginner", "enthusiast", "professional", "commercial"]);
export const rejectionReasonEnum = pgEnum("rejection_reason", ["out_of_focus", "poor_exposure", "poor_composition", "duplicate", "unwanted_subject", "other"]);
