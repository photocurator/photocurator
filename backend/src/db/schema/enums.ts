/**
 * @module db/schema/enums
 * This file defines various PostgreSQL enums used throughout the database schema.
 * Enums provide a way to create a new data type with a fixed set of possible values.
 */
import { pgEnum } from "drizzle-orm/pg-core";

/**
 * Enum for user subscription tiers.
 * - `free`: The default, free plan.
 * - `basic`: The basic paid plan.
 * - `premium`: The premium paid plan.
 * - `professional`: The professional-grade plan.
 */
export const subscriptionTierEnum = pgEnum("subscription_tier", ["free", "basic", "premium", "professional"]);

/**
 * Enum for the type of an image group.
 * - `similar`: A group of visually similar images.
 * - `burst`: Images taken in a rapid burst sequence.
 * - `sequence`: Images that form a logical sequence (e.g., panorama).
 * - `time_based`: Images grouped by close proximity in time.
 */
export const groupTypeEnum = pgEnum("group_type", ["similar", "burst", "sequence", "time_based", "gps"]);

/**
 * Enum for the type of analysis job.
 * - `quality_analysis`: Job to assess image quality.
 * - `object_detection`: Job to detect objects within images.
 * - `similarity_grouping`: Job to group similar images.
 * - `best_shot_recommendation`: Job to recommend the best shot from a group.
 */
export const jobTypeEnum = pgEnum("job_type", ["quality_analysis", "object_detection", "similarity_grouping", "best_shot_recommendation", "exif_analysis", "image_captioning", "gps_grouping"]);

/**
 * Enum for the status of a bulk analysis job.
 * - `pending`: The job has been created but not yet started.
 * - `processing`: The job is currently in progress.
 * - `completed`: The job has finished successfully.
 * - `failed`: The job terminated with an error.
 * - `cancelled`: The job was cancelled by a user.
 */
export const jobStatusEnum = pgEnum("job_status", ["pending", "processing", "completed", "failed", "cancelled"]);

/**
 * Enum for the status of an individual item within a job.
 * - `pending`: The item is waiting to be processed.
 * - `processing`: The item is currently being processed.
 * - `completed`: The item was processed successfully.
 * - `failed`: Processing the item resulted in an error.
 * - `skipped`: The item was skipped and not processed.
 */
export const itemStatusEnum = pgEnum("item_status", ["pending", "processing", "completed", "failed", "skipped"]);

/**
 * Enum for the type of search performed.
 * - `text`: Search based on captions or tags.
 * - `metadata`: Search based on EXIF or other metadata.
 * - `visual`: Search for visually similar images.
 * - `semantic`: Search based on the meaning or context of the image.
 */
export const searchTypeEnum = pgEnum("search_type", ["text", "metadata", "visual", "semantic"]);

/**
 * Enum for the type of advertisement.
 * - `camera`: Advertisement for a camera body.
 * - `lens`: Advertisement for a camera lens.
 * - `accessory`: Advertisement for a camera accessory (e.g., tripod, bag).
 * - `software`: Advertisement for photo editing software.
 * - `service`: Advertisement for a photography-related service.
 */
export const adTypeEnum = pgEnum("ad_type", ["camera", "lens", "accessory", "software", "service"]);

/**
 * Enum for user segments used in ad targeting.
 * - `beginner`: Users who are new to photography.
 * - `enthusiast`: Hobbyist photographers.
 * - `professional`: Professional photographers.
 * - `commercial`: Commercial or studio photographers.
 */
export const userSegmentEnum = pgEnum("user_segment", ["beginner", "enthusiast", "professional", "commercial"]);

/**
 * Enum for reasons why a user might reject an image.
 * - `out_of_focus`: The image is blurry or out of focus.
 * - `poor_exposure`: The image is too bright or too dark.
 * - `poor_composition`: The subject is poorly framed or the composition is weak.
 * - `duplicate`: The image is a duplicate of another.
 * - `unwanted_subject`: The image contains an unwanted person or object.
 * - `other`: A reason not covered by the other options.
 */
export const rejectionReasonEnum = pgEnum("rejection_reason", ["out_of_focus", "poor_exposure", "poor_composition", "duplicate", "unwanted_subject", "other"]);
