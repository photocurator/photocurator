CREATE TYPE "public"."ad_type" AS ENUM('camera', 'lens', 'accessory', 'software', 'service');--> statement-breakpoint
CREATE TYPE "public"."group_type" AS ENUM('similar', 'burst', 'sequence', 'time_based');--> statement-breakpoint
CREATE TYPE "public"."item_status" AS ENUM('pending', 'processing', 'completed', 'failed', 'skipped');--> statement-breakpoint
CREATE TYPE "public"."job_status" AS ENUM('pending', 'processing', 'completed', 'failed', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."job_type" AS ENUM('quality_analysis', 'object_detection', 'similarity_grouping', 'best_shot_recommendation');--> statement-breakpoint
CREATE TYPE "public"."rejection_reason" AS ENUM('out_of_focus', 'poor_exposure', 'poor_composition', 'duplicate', 'unwanted_subject', 'other');--> statement-breakpoint
CREATE TYPE "public"."search_type" AS ENUM('text', 'metadata', 'visual', 'semantic');--> statement-breakpoint
CREATE TYPE "public"."subscription_tier" AS ENUM('free', 'basic', 'premium', 'professional');--> statement-breakpoint
CREATE TYPE "public"."user_segment" AS ENUM('beginner', 'enthusiast', 'professional', 'commercial');--> statement-breakpoint
CREATE TABLE "account" (
	"id" text PRIMARY KEY NOT NULL,
	"account_id" text NOT NULL,
	"provider_id" text NOT NULL,
	"user_id" text NOT NULL,
	"access_token" text,
	"refresh_token" text,
	"id_token" text,
	"access_token_expires_at" timestamp,
	"refresh_token_expires_at" timestamp,
	"scope" text,
	"password" text,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "session" (
	"id" text PRIMARY KEY NOT NULL,
	"expires_at" timestamp NOT NULL,
	"token" text NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL,
	"ip_address" text,
	"user_agent" text,
	"user_id" text NOT NULL,
	CONSTRAINT "session_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "user" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"email" text NOT NULL,
	"email_verified" boolean DEFAULT false NOT NULL,
	"image" text,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL,
	CONSTRAINT "user_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE "verification" (
	"id" text PRIMARY KEY NOT NULL,
	"identifier" text NOT NULL,
	"value" text NOT NULL,
	"expires_at" timestamp NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "subscription" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"tier" "subscription_tier" NOT NULL,
	"start_date" timestamp NOT NULL,
	"end_date" timestamp,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_storage_quota" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"limit_bytes" bigint NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "project" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"project_name" text NOT NULL,
	"description" text,
	"cover_image_id" text,
	"is_archived" boolean DEFAULT false NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL,
	"archived_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "project_tag" (
	"id" text PRIMARY KEY NOT NULL,
	"project_id" text NOT NULL,
	"tag_name" text NOT NULL,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "image" (
	"id" text PRIMARY KEY NOT NULL,
	"project_id" text NOT NULL,
	"original_filename" text NOT NULL,
	"storage_path" text NOT NULL,
	"thumbnail_path" text,
	"file_size_bytes" bigint NOT NULL,
	"mime_type" text NOT NULL,
	"width_px" integer,
	"height_px" integer,
	"capture_datetime" timestamp,
	"upload_datetime" timestamp NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "image_exif" (
	"id" text PRIMARY KEY NOT NULL,
	"image_id" text NOT NULL,
	"camera_make" text,
	"camera_model" text,
	"lens_make" text,
	"lens_model" text,
	"focal_length_mm" numeric(10, 2),
	"aperture_f" numeric(10, 2),
	"shutter_speed" text,
	"iso" integer,
	"exposure_compensation" numeric(10, 2),
	"flash_fired" boolean,
	"white_balance" text,
	"shooting_mode" text,
	"orientation" integer,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "image_gps" (
	"id" text PRIMARY KEY NOT NULL,
	"image_id" text NOT NULL,
	"latitude" numeric(10, 8) NOT NULL,
	"longitude" numeric(11, 8) NOT NULL,
	"altitude_m" numeric(10, 2),
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "image_selection" (
	"id" text PRIMARY KEY NOT NULL,
	"image_id" text NOT NULL,
	"user_id" text NOT NULL,
	"is_picked" boolean DEFAULT false NOT NULL,
	"is_rejected" boolean DEFAULT false NOT NULL,
	"rating" integer,
	"selected_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "image_group" (
	"id" text PRIMARY KEY NOT NULL,
	"project_id" text NOT NULL,
	"group_type" "group_type" NOT NULL,
	"representative_image_id" text,
	"time_range_start" timestamp,
	"time_range_end" timestamp,
	"similarity_score" numeric(5, 4),
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "image_group_membership" (
	"id" text PRIMARY KEY NOT NULL,
	"group_id" text NOT NULL,
	"image_id" text NOT NULL,
	"sequence_order" integer,
	"added_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "best_shot_recommendation" (
	"id" text PRIMARY KEY NOT NULL,
	"image_id" text NOT NULL,
	"group_id" text NOT NULL,
	"model_version" text NOT NULL,
	"updated_at" timestamp NOT NULL,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "object_tag" (
	"id" text PRIMARY KEY NOT NULL,
	"image_id" text NOT NULL,
	"tag_name" text NOT NULL,
	"tag_category" text,
	"confidence" numeric(5, 4),
	"bounding_box_x" integer,
	"bounding_box_y" integer,
	"bounding_box_width" integer,
	"bounding_box_height" integer,
	"model_version" text NOT NULL,
	"updated_at" timestamp NOT NULL,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "quality_score" (
	"id" text PRIMARY KEY NOT NULL,
	"image_id" text NOT NULL,
	"brisque_score" numeric(10, 4),
	"tenegrad_score" numeric(10, 4),
	"musiq_score" numeric(10, 4),
	"model_version" text NOT NULL,
	"updated_at" timestamp NOT NULL,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_rejection_reason" (
	"id" text PRIMARY KEY NOT NULL,
	"image_id" text NOT NULL,
	"user_id" text NOT NULL,
	"reason_code" "rejection_reason" NOT NULL,
	"reason_text" text,
	"rejected_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "analysis_job" (
	"id" text PRIMARY KEY NOT NULL,
	"project_id" text NOT NULL,
	"user_id" text NOT NULL,
	"job_type" "job_type" NOT NULL,
	"job_status" "job_status" DEFAULT 'pending' NOT NULL,
	"error_message" text,
	"started_at" timestamp,
	"completed_at" timestamp,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "analysis_job_item" (
	"id" text PRIMARY KEY NOT NULL,
	"job_id" text NOT NULL,
	"image_id" text NOT NULL,
	"item_status" "item_status" DEFAULT 'pending' NOT NULL,
	"error_message" text,
	"processing_time_ms" integer,
	"retry_count" integer DEFAULT 0 NOT NULL,
	"started_at" timestamp,
	"completed_at" timestamp,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "shooting_pattern" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"most_used_camera_id" text,
	"most_used_lens_id" text,
	"avg_iso" numeric(10, 2),
	"most_common_aperture" numeric(10, 2),
	"most_common_focal_length" numeric(10, 2),
	"total_photos_analyzed" integer DEFAULT 0 NOT NULL,
	"last_analyzed_at" timestamp,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_search" (
	"id" text PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"search_query" text NOT NULL,
	"search_type" "search_type" NOT NULL,
	"results_count" integer NOT NULL,
	"search_duration_ms" integer,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ad_impression" (
	"id" text PRIMARY KEY NOT NULL,
	"ad_id" text NOT NULL,
	"user_id" text NOT NULL,
	"project_id" text,
	"clicked" boolean DEFAULT false NOT NULL,
	"clicked_at" timestamp,
	"impression_date" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ad_targeting_rule" (
	"id" text PRIMARY KEY NOT NULL,
	"ad_id" text NOT NULL,
	"camera_model" text,
	"lens_model" text,
	"user_segment" "user_segment",
	"min_iso_usage" integer,
	"max_iso_usage" integer,
	"min_focal_length" numeric(10, 2),
	"max_focal_length" numeric(10, 2),
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "advertisement" (
	"id" text PRIMARY KEY NOT NULL,
	"ad_type" "ad_type" NOT NULL,
	"product_name" text NOT NULL,
	"product_description" text,
	"product_image_url" text,
	"affiliate_url" text NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp NOT NULL,
	"expires_at" timestamp
);
--> statement-breakpoint
ALTER TABLE "account" ADD CONSTRAINT "account_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "session" ADD CONSTRAINT "session_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "subscription" ADD CONSTRAINT "subscription_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_storage_quota" ADD CONSTRAINT "user_storage_quota_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "project" ADD CONSTRAINT "project_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "project_tag" ADD CONSTRAINT "project_tag_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image" ADD CONSTRAINT "image_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image_exif" ADD CONSTRAINT "image_exif_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image_gps" ADD CONSTRAINT "image_gps_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image_selection" ADD CONSTRAINT "image_selection_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image_selection" ADD CONSTRAINT "image_selection_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image_group" ADD CONSTRAINT "image_group_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image_group_membership" ADD CONSTRAINT "image_group_membership_group_id_image_group_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."image_group"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image_group_membership" ADD CONSTRAINT "image_group_membership_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "best_shot_recommendation" ADD CONSTRAINT "best_shot_recommendation_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "best_shot_recommendation" ADD CONSTRAINT "best_shot_recommendation_group_id_image_group_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."image_group"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "object_tag" ADD CONSTRAINT "object_tag_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quality_score" ADD CONSTRAINT "quality_score_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_rejection_reason" ADD CONSTRAINT "user_rejection_reason_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_rejection_reason" ADD CONSTRAINT "user_rejection_reason_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "analysis_job" ADD CONSTRAINT "analysis_job_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "analysis_job" ADD CONSTRAINT "analysis_job_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "analysis_job_item" ADD CONSTRAINT "analysis_job_item_job_id_analysis_job_id_fk" FOREIGN KEY ("job_id") REFERENCES "public"."analysis_job"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "analysis_job_item" ADD CONSTRAINT "analysis_job_item_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "shooting_pattern" ADD CONSTRAINT "shooting_pattern_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_search" ADD CONSTRAINT "user_search_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_impression" ADD CONSTRAINT "ad_impression_ad_id_advertisement_id_fk" FOREIGN KEY ("ad_id") REFERENCES "public"."advertisement"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_impression" ADD CONSTRAINT "ad_impression_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_impression" ADD CONSTRAINT "ad_impression_project_id_project_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."project"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ad_targeting_rule" ADD CONSTRAINT "ad_targeting_rule_ad_id_advertisement_id_fk" FOREIGN KEY ("ad_id") REFERENCES "public"."advertisement"("id") ON DELETE cascade ON UPDATE no action;