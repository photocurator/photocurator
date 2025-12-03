ALTER TYPE "public"."job_type" ADD VALUE 'thumbnail_generation' BEFORE 'quality_analysis';--> statement-breakpoint
ALTER TABLE "image_selection" DROP CONSTRAINT "image_selection_image_id_user_id_unique";--> statement-breakpoint
ALTER TABLE "image_selection" ADD CONSTRAINT "unique_selection" UNIQUE("image_id","user_id");