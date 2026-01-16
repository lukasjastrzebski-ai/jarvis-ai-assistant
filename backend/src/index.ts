import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { healthRoutes } from './routes/health';
import { apiRoutes } from './routes/api';
import { authRoutes } from './routes/auth';
import { syncRoutes } from './routes/sync';
import { rateLimiters } from './middleware/rateLimit';

export interface Env {
  ENVIRONMENT: string;
  API_VERSION: string;
  JWT_SECRET?: string;
  RATE_LIMIT_ENABLED?: string;
}

const app = new Hono<{ Bindings: Env }>();

// Global middleware
app.use('*', logger());
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  exposeHeaders: ['X-RateLimit-Limit', 'X-RateLimit-Remaining', 'X-RateLimit-Reset'],
}));

// Apply rate limiting to API routes (skip in test environment)
app.use('/api/*', async (c, next) => {
  if (c.env.ENVIRONMENT === 'test' || c.env.RATE_LIMIT_ENABLED === 'false') {
    return next();
  }
  return rateLimiters.standard(c, next);
});

// Apply stricter rate limiting to auth routes
app.use('/auth/*', async (c, next) => {
  if (c.env.ENVIRONMENT === 'test' || c.env.RATE_LIMIT_ENABLED === 'false') {
    return next();
  }
  return rateLimiters.strict(c, next);
});

// Routes
app.route('/health', healthRoutes);
app.route('/api/v1', apiRoutes);
app.route('/auth', authRoutes);
app.route('/sync', syncRoutes);

// Root endpoint - API gateway info
app.get('/', (c) => {
  return c.json({
    name: 'Jarvis API Gateway',
    version: c.env.API_VERSION,
    environment: c.env.ENVIRONMENT,
    endpoints: {
      health: '/health',
      api: '/api/v1',
      auth: '/auth',
      sync: '/sync',
    },
    documentation: '/docs',
  });
});

// API documentation placeholder
app.get('/docs', (c) => {
  return c.json({
    openapi: '3.0.0',
    info: {
      title: 'Jarvis API',
      version: c.env.API_VERSION,
      description: 'AI-powered personal assistant API',
    },
    servers: [
      { url: 'http://localhost:8787', description: 'Development' },
    ],
    paths: {
      '/health': { get: { summary: 'Health check' } },
      '/health/ready': { get: { summary: 'Readiness check' } },
      '/health/live': { get: { summary: 'Liveness probe' } },
      '/auth/register': { post: { summary: 'Register user' } },
      '/auth/login': { post: { summary: 'Login user' } },
      '/auth/refresh': { post: { summary: 'Refresh tokens' } },
      '/auth/me': { get: { summary: 'Get current user' } },
      '/api/v1/version': { get: { summary: 'API version' } },
      '/api/v1/inbox': { get: { summary: 'Get inbox items' } },
      '/api/v1/calendar': { get: { summary: 'Get calendar events' } },
    },
  });
});

// 404 handler
app.notFound((c) => {
  return c.json({
    error: 'Not Found',
    message: `The path ${c.req.path} does not exist`,
    availableEndpoints: ['/', '/health', '/api/v1', '/auth', '/docs'],
  }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error('Error:', err);

  // Don't expose internal errors in production
  if (c.env.ENVIRONMENT === 'production') {
    return c.json({ error: 'Internal Server Error' }, 500);
  }

  return c.json({
    error: 'Internal Server Error',
    message: err.message,
  }, 500);
});

export default app;
