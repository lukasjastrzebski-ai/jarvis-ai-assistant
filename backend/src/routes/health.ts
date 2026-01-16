import { Hono } from 'hono';
import type { Env } from '../index';

export const healthRoutes = new Hono<{ Bindings: Env }>();

// Health check endpoint
healthRoutes.get('/', (c) => {
  return c.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
  });
});

// Detailed health with version info
healthRoutes.get('/ready', (c) => {
  return c.json({
    status: 'ready',
    version: c.env.API_VERSION,
    environment: c.env.ENVIRONMENT,
    timestamp: new Date().toISOString(),
  });
});

// Liveness probe (minimal response)
healthRoutes.get('/live', (c) => {
  return c.text('OK');
});
