import { Context, Next } from 'hono';

/**
 * Rate limit configuration
 */
interface RateLimitConfig {
  windowMs: number;      // Time window in milliseconds
  maxRequests: number;   // Max requests per window
  keyGenerator?: (c: Context) => string;
}

/**
 * In-memory rate limit store
 * In production, use Redis or similar for distributed rate limiting
 */
const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

/**
 * Default key generator - uses IP address or fallback
 */
function defaultKeyGenerator(c: Context): string {
  return c.req.header('CF-Connecting-IP') ||
         c.req.header('X-Forwarded-For')?.split(',')[0] ||
         c.req.header('X-Real-IP') ||
         'anonymous';
}

/**
 * Create rate limiting middleware
 */
export function rateLimit(config: RateLimitConfig) {
  const {
    windowMs,
    maxRequests,
    keyGenerator = defaultKeyGenerator,
  } = config;

  return async (c: Context, next: Next): Promise<Response | void> => {
    const key = keyGenerator(c);
    const now = Date.now();

    // Get or create rate limit entry
    let entry = rateLimitStore.get(key);

    if (!entry || now > entry.resetTime) {
      entry = {
        count: 0,
        resetTime: now + windowMs,
      };
    }

    entry.count++;
    rateLimitStore.set(key, entry);

    // Calculate remaining
    const remaining = Math.max(0, maxRequests - entry.count);
    const resetSeconds = Math.ceil((entry.resetTime - now) / 1000);

    // Set rate limit headers
    c.header('X-RateLimit-Limit', String(maxRequests));
    c.header('X-RateLimit-Remaining', String(remaining));
    c.header('X-RateLimit-Reset', String(resetSeconds));

    // Check if rate limited
    if (entry.count > maxRequests) {
      c.header('Retry-After', String(resetSeconds));
      return c.json(
        {
          error: 'Too Many Requests',
          message: `Rate limit exceeded. Try again in ${resetSeconds} seconds.`,
          retryAfter: resetSeconds,
        },
        429
      );
    }

    await next();
  };
}

/**
 * Preset rate limiters
 */
export const rateLimiters = {
  // Standard API rate limit: 100 requests per minute
  standard: rateLimit({
    windowMs: 60 * 1000,
    maxRequests: 100,
  }),

  // Strict rate limit: 10 requests per minute (for auth endpoints)
  strict: rateLimit({
    windowMs: 60 * 1000,
    maxRequests: 10,
  }),

  // Relaxed rate limit: 1000 requests per minute (for health checks)
  relaxed: rateLimit({
    windowMs: 60 * 1000,
    maxRequests: 1000,
  }),
};

/**
 * Clean up expired entries (call periodically)
 */
export function cleanupRateLimitStore(): void {
  const now = Date.now();
  for (const [key, entry] of rateLimitStore.entries()) {
    if (now > entry.resetTime) {
      rateLimitStore.delete(key);
    }
  }
}
