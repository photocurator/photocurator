/**
 * @module db/schema/index
 * This file serves as the main entry point for all database schema modules.
 * It aggregates and exports all the individual schema definitions, making them
 * available for use by the Drizzle ORM.
 */

// Export all enums
export * from "./enums";

// Export auth tables and relations
export * from "./auth";

// Export subscription tables and relations
export * from "./subscription";

// Export project tables and relations
export * from "./project";

// Export image tables and relations
export * from "./image";

// Export image group tables and relations
export * from "./imageGroup";

// Export analysis tables and relations
export * from "./analysis";

// Export job tables and relations
export * from "./jobs";

// Export user analytics tables and relations
export * from "./user";

// Export advertisement tables and relations
export * from "./advertisement";
