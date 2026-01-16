import { describe, it, expect } from 'vitest';
import app from '../src/index';
import { rateLimit, cleanupRateLimitStore } from '../src/middleware/rateLimit';
import { validateSchema, isValidEmail, isValidUUID, schemas } from '../src/utils/validation';

const mockEnv = {
  ENVIRONMENT: 'test',
  API_VERSION: '0.1.0',
  JWT_SECRET: 'test-secret-key',
};

interface GatewayResponse {
  name?: string;
  version?: string;
  environment?: string;
  endpoints?: Record<string, string>;
  documentation?: string;
  error?: string;
  message?: string;
  availableEndpoints?: string[];
  openapi?: string;
  info?: { title: string };
}

describe('API Gateway', () => {
  describe('Root endpoint', () => {
    it('should return gateway info', async () => {
      const res = await app.request('/', {}, mockEnv);
      expect(res.status).toBe(200);

      const json = await res.json() as GatewayResponse;
      expect(json.name).toBe('Jarvis API Gateway');
      expect(json.endpoints).toBeDefined();
      expect(json.documentation).toBe('/docs');
    });
  });

  describe('Documentation endpoint', () => {
    it('should return OpenAPI spec', async () => {
      const res = await app.request('/docs', {}, mockEnv);
      expect(res.status).toBe(200);

      const json = await res.json() as GatewayResponse;
      expect(json.openapi).toBe('3.0.0');
      expect(json.info?.title).toBe('Jarvis API');
    });
  });

  describe('404 handling', () => {
    it('should return helpful 404 response', async () => {
      const res = await app.request('/nonexistent', {}, mockEnv);
      expect(res.status).toBe(404);

      const json = await res.json() as GatewayResponse;
      expect(json.error).toBe('Not Found');
      expect(json.availableEndpoints).toBeDefined();
    });
  });
});

describe('Rate Limiting', () => {
  it('should create rate limiter with config', () => {
    const limiter = rateLimit({
      windowMs: 60000,
      maxRequests: 10,
    });
    expect(limiter).toBeDefined();
  });

  it('should cleanup expired entries', () => {
    cleanupRateLimitStore();
    // Should not throw
    expect(true).toBe(true);
  });
});

describe('Validation Utilities', () => {
  describe('isValidEmail', () => {
    it('should validate correct emails', () => {
      expect(isValidEmail('test@example.com')).toBe(true);
      expect(isValidEmail('user.name@domain.co.uk')).toBe(true);
    });

    it('should reject invalid emails', () => {
      expect(isValidEmail('invalid')).toBe(false);
      expect(isValidEmail('missing@domain')).toBe(false);
      expect(isValidEmail('@nodomain.com')).toBe(false);
    });
  });

  describe('isValidUUID', () => {
    it('should validate correct UUIDs', () => {
      expect(isValidUUID('550e8400-e29b-41d4-a716-446655440000')).toBe(true);
    });

    it('should reject invalid UUIDs', () => {
      expect(isValidUUID('not-a-uuid')).toBe(false);
      expect(isValidUUID('550e8400-e29b-41d4-a716')).toBe(false);
    });
  });

  describe('validateSchema', () => {
    it('should validate registration data', () => {
      const result = validateSchema(
        { email: 'test@example.com', password: 'password123' },
        schemas.register
      );
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject invalid registration data', () => {
      const result = validateSchema(
        { email: 'invalid', password: 'short' },
        schemas.register
      );
      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('should require fields marked as required', () => {
      const result = validateSchema(
        {},
        schemas.register
      );
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.field === 'email')).toBe(true);
      expect(result.errors.some(e => e.field === 'password')).toBe(true);
    });
  });
});
