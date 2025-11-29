ALTER TABLE "image_exif" ADD CONSTRAINT "image_exif_image_id_unique" UNIQUE("image_id");--> statement-breakpoint
ALTER TABLE "image_gps" ADD CONSTRAINT "image_gps_image_id_unique" UNIQUE("image_id");--> statement-breakpoint
ALTER TABLE "quality_score" ADD CONSTRAINT "quality_score_image_id_unique" UNIQUE("image_id");