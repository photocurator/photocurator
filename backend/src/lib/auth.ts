/**
 * @module lib/auth
 * This file configures the authentication service using the `better-auth` library.
 * It sets up the Drizzle database adapter and enables email and password authentication.
 */
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { db } from "../db";
import * as schema from "../db/schema";

/**
 * The configured `better-auth` instance.
 * This object is used to handle all authentication-related operations.
 * @type {betterAuth}
 */
export const auth = betterAuth({
    database: drizzleAdapter(db, {
        provider: "pg",
        schema: {
            user: schema.user,
            session: schema.session,
            account: schema.account,
            verification: schema.verification,
        },
    }),
    emailAndPassword: {
        enabled: true,
    },
    user: {
        additionalFields: {
            nickname: {
                type: "string",
                required: false,
                returned: true,
                input: true,
            },
        },
    },
    advanced: {
        disableOriginCheck: true,
    },
});

/**
 * Defines the types for the user and session objects provided by `better-auth`.
 * @property {object | null} user - The authenticated user object, or null if not authenticated.
 * @property {object | null} session - The user's session object, or null if not authenticated.
 */
export type AuthType = {
    user: typeof auth.$Infer.Session.user | null
    session: typeof auth.$Infer.Session.session | null
}
