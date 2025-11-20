import { pgTable, text, timestamp, boolean, bigint, integer, decimal } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { project } from "./project";
import { user } from "./auth";
import { imageCaption, qualityScore, bestShotRecommendation, objectTag  } from "./analysis";
import { imageGroupMembership } from "./imageGroup";

export const image = pgTable("image", {
  id: text("id").primaryKey(),
  userId: text("user_id")
    .references(() => user.id, { onDelete: "cascade" }),
  projectId: text("project_id")
    .notNull()
    .references(() => project.id, { onDelete: "cascade" }),
  originalFilename: text("original_filename").notNull(),
  storagePath: text("storage_path").notNull(),
  thumbnailPath: text("thumbnail_path"),
  fileSizeBytes: bigint("file_size_bytes", { mode: "number" }).notNull(),
  mimeType: text("mime_type").notNull(),
  widthPx: integer("width_px"),
  heightPx: integer("height_px"),
  compareViewSelected: boolean("compare_view_selected").default(false).notNull(),
  captureDatetime: timestamp("capture_datetime"),
  uploadDatetime: timestamp("upload_datetime")
    .$defaultFn(() => new Date())
    .notNull(),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
});

export const imageEXIF = pgTable("image_exif", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  cameraMake: text("camera_make"),
  cameraModel: text("camera_model"),
  lensMake: text("lens_make"),
  lensModel: text("lens_model"),
  focalLengthMm: decimal("focal_length_mm", { precision: 10, scale: 2 }),
  apertureF: decimal("aperture_f", { precision: 10, scale: 2 }),
  shutterSpeed: text("shutter_speed"),
  iso: integer("iso"),
  exposureCompensation: decimal("exposure_compensation", { precision: 10, scale: 2 }),
  flashFired: boolean("flash_fired"),
  whiteBalance: text("white_balance"),
  shootingMode: text("shooting_mode"),
  orientation: integer("orientation"),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

export const imageGPS = pgTable("image_gps", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  latitude: decimal("latitude", { precision: 10, scale: 8 }).notNull(),
  longitude: decimal("longitude", { precision: 11, scale: 8 }).notNull(),
  altitudeM: decimal("altitude_m", { precision: 10, scale: 2 }),
  createdAt: timestamp("created_at")
    .$defaultFn(() => new Date())
    .notNull(),
});

export const imageSelection = pgTable("image_selection", {
  id: text("id").primaryKey(),
  imageId: text("image_id")
    .notNull()
    .references(() => image.id, { onDelete: "cascade" }),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  isPicked: boolean("is_picked").default(false).notNull(),
  isRejected: boolean("is_rejected").default(false).notNull(),
  rating: integer("rating"),
  selectedAt: timestamp("selected_at")
    .$defaultFn(() => new Date())
    .notNull(),
  updatedAt: timestamp("updated_at")
    .$defaultFn(() => new Date())
    .$onUpdate(() => new Date())
    .notNull(),
});

// Relations
export const imageRelations = relations(image, ({ one, many }) => ({
  user: one(user, {
    fields: [image.userId],
    references: [user.id],
  }),
  project: one(project, {
    fields: [image.projectId],
    references: [project.id],
  }),
  exif: one(imageEXIF, {
    fields: [image.id],
    references: [imageEXIF.imageId],
  }),
  gps: one(imageGPS, {
    fields: [image.id],
    references: [imageGPS.imageId],
  }),
  selection: one(imageSelection, {
    fields: [image.id],
    references: [imageSelection.imageId],
  }),
  captions: many(imageCaption),
  groupMemberships: many(imageGroupMembership),
  selections: many(imageSelection),
  qualityScores: many(qualityScore),
  bestShotRecommendations: many(bestShotRecommendation),
  objectTags: many(objectTag),
}));

export const imageEXIFRelations = relations(imageEXIF, ({ one }) => ({
  image: one(image, {
    fields: [imageEXIF.imageId],
    references: [image.id],
  }),
}));

export const imageGPSRelations = relations(imageGPS, ({ one }) => ({
  image: one(image, {
    fields: [imageGPS.imageId],
    references: [image.id],
  }),
}));

export const imageSelectionRelations = relations(imageSelection, ({ one }) => ({
  image: one(image, {
    fields: [imageSelection.imageId],
    references: [image.id],
  }),
  user: one(user, {
    fields: [imageSelection.userId],
    references: [user.id],
  }),
}));
