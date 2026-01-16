import { Hono } from 'hono';
import { generateTokenPair, verifyToken, JWTPayload } from '../utils/jwt';
import { authMiddleware } from '../middleware/auth';
import type { Env } from '../index';

// Define variables type for typed context
type Variables = {
  user: JWTPayload;
};

export const authRoutes = new Hono<{ Bindings: Env; Variables: Variables }>();

// In-memory user store (replace with database in production)
interface User {
  id: string;
  email: string;
  passwordHash: string;
  createdAt: string;
}

const users = new Map<string, User>();

/**
 * Simple password hashing (use bcrypt/argon2 in production)
 */
async function hashPassword(password: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(password);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = new Uint8Array(hashBuffer);
  return Array.from(hashArray).map(b => b.toString(16).padStart(2, '0')).join('');
}

function getJwtSecret(c: { env: Env }): string {
  return c.env.JWT_SECRET || 'development-secret-change-in-production';
}

/**
 * Register new user
 */
authRoutes.post('/register', async (c) => {
  const body = await c.req.json().catch(() => null);

  if (!body || !body.email || !body.password) {
    return c.json({ error: 'Email and password required' }, 400);
  }

  const { email, password } = body;

  // Validate email format
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return c.json({ error: 'Invalid email format' }, 400);
  }

  // Validate password length
  if (password.length < 8) {
    return c.json({ error: 'Password must be at least 8 characters' }, 400);
  }

  // Check if user already exists
  const existingUser = Array.from(users.values()).find(u => u.email === email);
  if (existingUser) {
    return c.json({ error: 'User already exists' }, 409);
  }

  // Create user
  const userId = crypto.randomUUID();
  const passwordHash = await hashPassword(password);

  const user: User = {
    id: userId,
    email,
    passwordHash,
    createdAt: new Date().toISOString(),
  };

  users.set(userId, user);

  // Generate tokens
  const secret = getJwtSecret(c);
  const tokens = await generateTokenPair(userId, email, secret);

  return c.json({
    user: { id: userId, email },
    ...tokens,
  }, 201);
});

/**
 * Login user
 */
authRoutes.post('/login', async (c) => {
  const body = await c.req.json().catch(() => null);

  if (!body || !body.email || !body.password) {
    return c.json({ error: 'Email and password required' }, 400);
  }

  const { email, password } = body;

  // Find user
  const user = Array.from(users.values()).find(u => u.email === email);
  if (!user) {
    return c.json({ error: 'Invalid credentials' }, 401);
  }

  // Verify password
  const passwordHash = await hashPassword(password);
  if (user.passwordHash !== passwordHash) {
    return c.json({ error: 'Invalid credentials' }, 401);
  }

  // Generate tokens
  const secret = getJwtSecret(c);
  const tokens = await generateTokenPair(user.id, user.email, secret);

  return c.json({
    user: { id: user.id, email: user.email },
    ...tokens,
  });
});

/**
 * Refresh tokens
 */
authRoutes.post('/refresh', async (c) => {
  const body = await c.req.json().catch(() => null);

  if (!body || !body.refreshToken) {
    return c.json({ error: 'Refresh token required' }, 400);
  }

  const { refreshToken } = body;

  // Verify refresh token
  const secret = getJwtSecret(c);
  const payload = await verifyToken(refreshToken, secret);

  if (!payload || payload.type !== 'refresh') {
    return c.json({ error: 'Invalid refresh token' }, 401);
  }

  // Find user
  const user = users.get(payload.sub);
  if (!user) {
    return c.json({ error: 'User not found' }, 404);
  }

  // Generate new tokens
  const tokens = await generateTokenPair(user.id, user.email, secret);

  return c.json(tokens);
});

/**
 * Get current user (protected route)
 */
authRoutes.get('/me', authMiddleware, (c) => {
  const user = c.get('user');
  return c.json({
    id: user.sub,
    email: user.email,
  });
});

/**
 * Logout (client-side token invalidation)
 * In production, maintain a token blacklist
 */
authRoutes.post('/logout', (c) => {
  return c.json({ message: 'Logged out successfully' });
});
