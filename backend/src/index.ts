/**
 * @module index
 * This file is the main entry point for the Hono web server.
 * It sets up the server, defines middleware for authentication, and registers API routes.
 */
import { OpenAPIHono } from 'hono-zod-openapi';
import { swaggerUI } from '@hono/swagger-ui';
import { auth, AuthType } from './lib/auth';
import projects from './routes/projects';
import images from './routes/images';
import users from './routes/users';
import ads from './routes/ads';

/**
 * Defines the variables that will be available on the Hono context.
 * @property {AuthType['user']} user - The authenticated user object, or null if not authenticated.
 * @property {AuthType['session']} session - The user's session object, or null if not authenticated.
 */
type Variables = {
  user: AuthType['user'];
  session: AuthType['session'];
};

const app = new OpenAPIHono<{ Variables: Variables }>();

/**
 * Middleware that runs on all routes to handle session authentication.
 * It checks for a session in the request headers, and if one is found,
 * it sets the 'user' and 'session' variables in the Hono context.
 * @param {Context} c - The Hono context object.
 * @param {Next} next - The next middleware function.
 */
app.use('*', async (c, next) => {
  const session = await auth.api.getSession({ headers: c.req.raw.headers });
  if (!session) {
    c.set('user', null);
    c.set('session', null);
    await next();
    return;
  }
  c.set('user', session.user);
  c.set('session', session.session);
  await next();
});

/**
 * Route handler for authentication-related requests.
 * It delegates the handling of authentication to the `auth.handler` function.
 * @param {Context} c - The Hono context object.
 * @returns {Response} The response from the authentication handler.
 */
app.on(['POST', 'GET'], '/api/auth/*', (c) => {
  return auth.handler(c.req.raw);
});

// Register API routes
app.route('/api/projects', projects);
app.route('/api/images', images);
app.route('/api/users', users);
app.route('/api/ads', ads);

// OpenAPI documentation endpoint
app.doc('/api/doc', {
  openapi: '3.0.0',
  info: {
    version: '1.0.0',
    title: 'PhotoCurator API',
  },
});

app.get('/api/ui', swaggerUI({ url: '/api/doc' }));

export default app;
