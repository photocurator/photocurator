CREATE TABLE "image_caption" (
	"id" text PRIMARY KEY NOT NULL,
	"image_id" text NOT NULL,
	"caption" text NOT NULL,
	"model_version" text NOT NULL,
	"updated_at" timestamp NOT NULL,
	"created_at" timestamp NOT NULL
);
--> statement-breakpoint
ALTER TABLE "image" ADD COLUMN "user_id" text;--> statement-breakpoint
ALTER TABLE "image" ADD COLUMN "compare_view_selected" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "image_caption" ADD CONSTRAINT "image_caption_image_id_image_id_fk" FOREIGN KEY ("image_id") REFERENCES "public"."image"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "image" ADD CONSTRAINT "image_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;