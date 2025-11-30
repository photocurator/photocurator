import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';
import { auth } from '../lib/auth';

const app = new OpenAPIHono();

const UserSchema = z.object({
    id: z.string(),
    email: z.string().email(),
    emailVerified: z.boolean(),
    name: z.string(),
    createdAt: z.string(),
    updatedAt: z.string(),
    image: z.string().nullable().optional(),
});

const SessionSchema = z.object({
    id: z.string(),
    expiresAt: z.date(),
    token: z.string(),
    createdAt: z.date(),
    updatedAt: z.date(),
    ipAddress: z.string().nullable().optional(),
    userAgent: z.string().nullable().optional(),
    userId: z.string(),
});

const AuthResponseSchema = z.object({
    user: UserSchema,
    session: SessionSchema,
});

const ErrorSchema = z.object({
    message: z.string().optional(),
    code: z.string().optional(),
});

const signInRoute = createRoute({
    method: 'post',
    path: '/sign-in/email',
    tags: ['Auth'],
    summary: 'Sign in with email and password',
    request: {
        body: {
            content: {
                'application/json': {
                    schema: z.object({
                        email: z.email(),
                        password: z.string(),
                    }),
                },
            },
        },
    },
    responses: {
        200: {
            description: 'Sign in successful',
            content: {
                'application/json': {
                    schema: AuthResponseSchema,
                },
            },
        },
        400: {
            description: 'Invalid input or credentials',
            content: {
                'application/json': {
                    schema: ErrorSchema,
                },
            },
        },
        500: {
            description: 'Internal server error',
            content: {
                'application/json': {
                    schema: ErrorSchema,
                },
            },
        },
    },
});

const signUpRoute = createRoute({
    method: 'post',
    path: '/sign-up/email',
    tags: ['Auth'],
    summary: 'Sign up with email, password, and name',
    request: {
        body: {
            content: {
                'application/json': {
                    schema: z.object({
                        email: z.email(),
                        password: z.string().min(8),
                        name: z.string().min(1),
                        image: z.string().optional(),
                    }),
                },
            },
        },
    },
    responses: {
        200: {
            description: 'Sign up successful',
            content: {
                'application/json': {
                    schema: AuthResponseSchema,
                },
            },
        },
        400: {
            description: 'Invalid input or user already exists',
            content: {
                'application/json': {
                    schema: ErrorSchema,
                },
            },
        },
        500: {
            description: 'Internal server error',
            content: {
                'application/json': {
                    schema: ErrorSchema,
                },
            },
        },
    },
});

app.openapi(signInRoute, async (c) => {
    const body = c.req.valid('json');
    // Reconstruct the request because the body has been consumed by validation
    const req = new Request(c.req.raw.url, {
        method: c.req.raw.method,
        headers: c.req.raw.headers,
        body: JSON.stringify(body),
    });
    return auth.handler(req) as any;
});

app.openapi(signUpRoute, async (c) => {
    const body = c.req.valid('json');
    // Reconstruct the request because the body has been consumed by validation
    const req = new Request(c.req.raw.url, {
        method: c.req.raw.method,
        headers: c.req.raw.headers,
        body: JSON.stringify(body),
    });
    return auth.handler(req) as any;
});

// Catch-all route for other auth endpoints not explicitly documented (e.g., session, sign-out)
app.all('/*', async (c) => {
    return auth.handler(c.req.raw);
});

export default app;

