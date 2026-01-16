import { describe, it, expect } from 'vitest';
import app from '../src/index';

const mockEnv = {
  ENVIRONMENT: 'test',
  API_VERSION: '0.1.0',
};

interface ApiResponse {
  name?: string;
  version?: string;
  status?: string;
  timestamp?: string;
  api_version?: string;
  build_date?: string;
  items?: unknown[];
  events?: unknown[];
  count?: number;
  message?: string;
  error?: string;
  path?: string;
  environment?: string;
}

describe('Jarvis API', () => {
  describe('Root endpoint', () => {
    it('should return API info', async () => {
      const res = await app.request('/', {}, mockEnv);
      expect(res.status).toBe(200);

      const json = await res.json() as ApiResponse;
      expect(json.name).toBe('Jarvis API Gateway');
      expect(json.version).toBe('0.1.0');
    });
  });

  describe('Health endpoints', () => {
    it('should return healthy status', async () => {
      const res = await app.request('/health', {}, mockEnv);
      expect(res.status).toBe(200);

      const json = await res.json() as ApiResponse;
      expect(json.status).toBe('healthy');
      expect(json.timestamp).toBeDefined();
    });

    it('should return ready status with version', async () => {
      const res = await app.request('/health/ready', {}, mockEnv);
      expect(res.status).toBe(200);

      const json = await res.json() as ApiResponse;
      expect(json.status).toBe('ready');
      expect(json.version).toBe('0.1.0');
    });

    it('should return OK for liveness', async () => {
      const res = await app.request('/health/live', {}, mockEnv);
      expect(res.status).toBe(200);

      const text = await res.text();
      expect(text).toBe('OK');
    });
  });

  describe('API v1 endpoints', () => {
    it('should return version info', async () => {
      const res = await app.request('/api/v1/version', {}, mockEnv);
      expect(res.status).toBe(200);

      const json = await res.json() as ApiResponse;
      expect(json.api_version).toBe('0.1.0');
    });

    it('should return empty inbox', async () => {
      const res = await app.request('/api/v1/inbox', {}, mockEnv);
      expect(res.status).toBe(200);

      const json = await res.json() as ApiResponse;
      expect(json.items).toEqual([]);
      expect(json.count).toBe(0);
    });

    it('should return empty calendar', async () => {
      const res = await app.request('/api/v1/calendar', {}, mockEnv);
      expect(res.status).toBe(200);

      const json = await res.json() as ApiResponse;
      expect(json.events).toEqual([]);
    });
  });

  describe('Error handling', () => {
    it('should return 404 for unknown routes', async () => {
      const res = await app.request('/unknown-route', {}, mockEnv);
      expect(res.status).toBe(404);

      const json = await res.json() as ApiResponse;
      expect(json.error).toBe('Not Found');
    });
  });
});
