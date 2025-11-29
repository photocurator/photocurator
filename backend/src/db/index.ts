/**
 * @module db/index
 * This file initializes the database connection using Drizzle ORM.
 * It imports the database schema and exports a configured database instance.
 */
import * as schema from './schema';
import { drizzle } from 'drizzle-orm/bun-sql';

/**
 * The Drizzle ORM database instance.
 * This is the primary object used to interact with the database.
 * @type {drizzle}
 */
export const db = drizzle(process.env.DATABASE_URL!, { schema });
