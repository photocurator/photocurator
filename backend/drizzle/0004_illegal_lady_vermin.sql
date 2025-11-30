ALTER TYPE "public"."group_type" ADD VALUE IF NOT EXISTS 'gps';--> statement-breakpoint
ALTER TYPE "public"."job_type" ADD VALUE IF NOT EXISTS 'exif_analysis';--> statement-breakpoint
ALTER TYPE "public"."job_type" ADD VALUE IF NOT EXISTS 'image_captioning';--> statement-breakpoint
ALTER TYPE "public"."job_type" ADD VALUE IF NOT EXISTS 'gps_grouping';