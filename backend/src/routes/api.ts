import { Hono } from 'hono';
import type { Env } from '../index';

export const apiRoutes = new Hono<{ Bindings: Env }>();

// Version endpoint
apiRoutes.get('/version', (c) => {
  return c.json({
    api_version: c.env.API_VERSION,
    build_date: '2026-01-15',
  });
});

// Placeholder endpoints for future features
apiRoutes.get('/inbox', (c) => {
  return c.json({
    items: [],
    count: 0,
    message: 'Inbox endpoint - implementation pending',
  });
});

apiRoutes.get('/calendar', (c) => {
  return c.json({
    events: [],
    count: 0,
    message: 'Calendar endpoint - implementation pending',
  });
});

apiRoutes.post('/ai/chat', async (c) => {
  const body = await c.req.json().catch(() => ({}));
  return c.json({
    message: 'AI chat endpoint - implementation pending',
    received: body,
  });
});
