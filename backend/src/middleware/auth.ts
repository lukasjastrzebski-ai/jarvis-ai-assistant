import { Context, Next } from 'hono';
import { verifyToken, JWTPayload } from '../utils/jwt';

/**
 * Extended context with authenticated user
 */
export interface AuthContext {
  user: JWTPayload;
}

/**
 * Get JWT secret from environment
 */
function getJwtSecret(c: Context): string {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return (c.env as any).JWT_SECRET || 'development-secret-change-in-production';
}

/**
 * Extract Bearer token from Authorization header
 */
function extractBearerToken(authHeader: string | undefined): string | null {
  if (!authHeader) return null;
  if (!authHeader.startsWith('Bearer ')) return null;
  return authHeader.slice(7);
}

/**
 * Authentication middleware
 * Verifies JWT token and adds user to context
 */
export async function authMiddleware(c: Context, next: Next): Promise<Response | void> {
  const authHeader = c.req.header('Authorization');
  const token = extractBearerToken(authHeader);

  if (!token) {
    return c.json({ error: 'Missing authorization token' }, 401);
  }

  const secret = getJwtSecret(c);
  const payload = await verifyToken(token, secret);

  if (!payload) {
    return c.json({ error: 'Invalid or expired token' }, 401);
  }

  if (payload.type !== 'access') {
    return c.json({ error: 'Invalid token type' }, 401);
  }

  // Add user to context
  c.set('user', payload);

  await next();
}

/**
 * Optional auth middleware - doesn't fail if no token
 */
export async function optionalAuthMiddleware(c: Context, next: Next): Promise<void> {
  const authHeader = c.req.header('Authorization');
  const token = extractBearerToken(authHeader);

  if (token) {
    const secret = getJwtSecret(c);
    const payload = await verifyToken(token, secret);

    if (payload && payload.type === 'access') {
      c.set('user', payload);
    }
  }

  await next();
}
