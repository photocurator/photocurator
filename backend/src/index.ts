import { Hono } from 'hono';
import { auth, AuthType } from './lib/auth';
import projects from './routes/projects';
import images from './routes/images';
import users from './routes/users';
import ads from './routes/ads';

type Variables = {
  user: AuthType['user'];
  session: AuthType['session'];
};

const app = new Hono<{ Variables: Variables }>();

app.get('/', (c) => {
  return c.text('Hello Hono!');
});

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

app.on(['POST', 'GET'], '/api/auth/*', (c) => {
  return auth.handler(c.req.raw);
});

app.route('/api/projects', projects);
app.route('/api/images', images);
app.route('/api/users', users);
app.route('/api/ads', ads);

export default app;
