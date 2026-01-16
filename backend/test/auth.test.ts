import { describe, it, expect } from 'vitest';
import app from '../src/index';

const mockEnv = {
  ENVIRONMENT: 'test',
  API_VERSION: '0.1.0',
  JWT_SECRET: 'test-secret-key',
};

interface AuthResponse {
  user?: { id: string; email: string };
  accessToken?: string;
  refreshToken?: string;
  expiresIn?: number;
  error?: string;
  message?: string;
  id?: string;
  email?: string;
}

describe('Auth Routes', () => {
  describe('POST /auth/register', () => {
    it('should register a new user', async () => {
      const res = await app.request('/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'test@example.com',
          password: 'password123',
        }),
      }, mockEnv);

      expect(res.status).toBe(201);
      const json = await res.json() as AuthResponse;
      expect(json.user?.email).toBe('test@example.com');
      expect(json.accessToken).toBeDefined();
      expect(json.refreshToken).toBeDefined();
    });

    it('should reject invalid email', async () => {
      const res = await app.request('/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'invalid-email',
          password: 'password123',
        }),
      }, mockEnv);

      expect(res.status).toBe(400);
      const json = await res.json() as AuthResponse;
      expect(json.error).toContain('Invalid email');
    });

    it('should reject short password', async () => {
      const res = await app.request('/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'test2@example.com',
          password: 'short',
        }),
      }, mockEnv);

      expect(res.status).toBe(400);
      const json = await res.json() as AuthResponse;
      expect(json.error).toContain('Password must be at least 8 characters');
    });

    it('should reject missing fields', async () => {
      const res = await app.request('/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      }, mockEnv);

      expect(res.status).toBe(400);
      const json = await res.json() as AuthResponse;
      expect(json.error).toContain('required');
    });
  });

  describe('POST /auth/login', () => {
    it('should login with valid credentials', async () => {
      // First register
      await app.request('/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'login@example.com',
          password: 'password123',
        }),
      }, mockEnv);

      // Then login
      const res = await app.request('/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'login@example.com',
          password: 'password123',
        }),
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as AuthResponse;
      expect(json.accessToken).toBeDefined();
      expect(json.refreshToken).toBeDefined();
    });

    it('should reject invalid credentials', async () => {
      const res = await app.request('/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'nonexistent@example.com',
          password: 'wrongpassword',
        }),
      }, mockEnv);

      expect(res.status).toBe(401);
      const json = await res.json() as AuthResponse;
      expect(json.error).toContain('Invalid credentials');
    });
  });

  describe('POST /auth/refresh', () => {
    it('should refresh tokens', async () => {
      // Register and get tokens
      const registerRes = await app.request('/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'refresh@example.com',
          password: 'password123',
        }),
      }, mockEnv);

      const registerJson = await registerRes.json() as AuthResponse;

      // Use refresh token
      const res = await app.request('/auth/refresh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          refreshToken: registerJson.refreshToken,
        }),
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as AuthResponse;
      expect(json.accessToken).toBeDefined();
      expect(json.refreshToken).toBeDefined();
    });

    it('should reject invalid refresh token', async () => {
      const res = await app.request('/auth/refresh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          refreshToken: 'invalid-token',
        }),
      }, mockEnv);

      expect(res.status).toBe(401);
    });
  });

  describe('GET /auth/me', () => {
    it('should return current user with valid token', async () => {
      // Register and get tokens
      const registerRes = await app.request('/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'me@example.com',
          password: 'password123',
        }),
      }, mockEnv);

      const registerJson = await registerRes.json() as AuthResponse;

      // Get current user
      const res = await app.request('/auth/me', {
        headers: {
          Authorization: `Bearer ${registerJson.accessToken}`,
        },
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as AuthResponse;
      expect(json.email).toBe('me@example.com');
    });

    it('should reject request without token', async () => {
      const res = await app.request('/auth/me', {}, mockEnv);

      expect(res.status).toBe(401);
      const json = await res.json() as AuthResponse;
      expect(json.error).toContain('Missing authorization token');
    });

    it('should reject request with invalid token', async () => {
      const res = await app.request('/auth/me', {
        headers: {
          Authorization: 'Bearer invalid-token',
        },
      }, mockEnv);

      expect(res.status).toBe(401);
    });
  });

  describe('POST /auth/logout', () => {
    it('should return success message', async () => {
      const res = await app.request('/auth/logout', {
        method: 'POST',
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as AuthResponse;
      expect(json.message).toContain('Logged out');
    });
  });
});
