import { describe, it, expect, beforeEach } from 'vitest';
import app from '../src/index';
import { resetDb } from '../src/db';
import { generateTokenPair } from '../src/utils/jwt';

const mockEnv = {
  ENVIRONMENT: 'test',
  API_VERSION: '0.1.0',
  JWT_SECRET: 'test-secret-key-for-jwt-signing',
};

interface SyncResponse {
  items?: unknown[];
  memories?: unknown[];
  lastSyncTimestamp?: string;
  success?: boolean;
  results?: {
    itemsCreated: number;
    itemsUpdated: number;
    memoriesCreated: number;
    memoriesUpdated: number;
    conflicts: unknown[];
  };
  push?: {
    itemsCreated: number;
    itemsUpdated: number;
  };
  pull?: {
    items: unknown[];
    memories: unknown[];
  };
  conflicts?: unknown[];
  serverTimestamp?: string;
  userId?: string;
  itemCount?: number;
  memoryCount?: number;
  serverTime?: string;
  error?: string;
}

describe('Sync Routes', () => {
  let accessToken: string;
  const testUserId = 'test-user-sync-123';

  beforeEach(async () => {
    resetDb();
    const tokens = await generateTokenPair(testUserId, 'sync@example.com', mockEnv.JWT_SECRET);
    accessToken = tokens.accessToken;
  });

  describe('POST /sync/pull', () => {
    it('should return empty data for new user', async () => {
      const res = await app.request('/sync/pull', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({}),
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as SyncResponse;
      expect(json.items).toEqual([]);
      expect(json.memories).toEqual([]);
      expect(json.lastSyncTimestamp).toBeDefined();
    });

    it('should require authentication', async () => {
      const res = await app.request('/sync/pull', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
      }, mockEnv);

      expect(res.status).toBe(401);
    });

    it('should return data since last sync timestamp', async () => {
      const res = await app.request('/sync/pull', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          lastSyncTimestamp: new Date(Date.now() - 86400000).toISOString(),
        }),
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as SyncResponse;
      expect(json.lastSyncTimestamp).toBeDefined();
    });
  });

  describe('POST /sync/push', () => {
    it('should accept and save items', async () => {
      const item = {
        id: 'item-push-1',
        user_id: testUserId,
        title: 'Pushed Item',
        content: null,
        item_type: 'task',
        status: 'inbox',
        priority: 1,
        due_date: null,
        completed_at: null,
        created_at: new Date(),
        updated_at: new Date(),
        tags: [],
        parent_id: null,
        source_id: null,
        source_type: null,
        deleted_at: null,
      };

      const res = await app.request('/sync/push', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          items: [item],
          lastSyncTimestamp: new Date().toISOString(),
        }),
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as SyncResponse;
      expect(json.success).toBe(true);
      expect(json.results?.itemsCreated).toBe(1);
    });

    it('should detect conflicts', async () => {
      // First, push an item
      const item = {
        id: 'item-conflict-1',
        user_id: testUserId,
        title: 'Original Item',
        item_type: 'task',
        status: 'inbox',
        priority: 1,
        created_at: new Date(),
        updated_at: new Date(),
        tags: [],
      };

      await app.request('/sync/push', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({ items: [item] }),
      }, mockEnv);

      // Then try to push an older version
      const olderItem = {
        ...item,
        title: 'Older Version',
        updated_at: new Date(Date.now() - 86400000), // 1 day ago
      };

      const res = await app.request('/sync/push', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({ items: [olderItem] }),
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as SyncResponse;
      expect(json.results?.conflicts?.length).toBeGreaterThan(0);
    });

    it('should require authentication', async () => {
      const res = await app.request('/sync/push', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ items: [] }),
      }, mockEnv);

      expect(res.status).toBe(401);
    });
  });

  describe('POST /sync/full', () => {
    it('should perform bi-directional sync', async () => {
      const localItem = {
        id: 'item-full-1',
        user_id: testUserId,
        title: 'Local Item',
        item_type: 'task',
        status: 'inbox',
        priority: 1,
        created_at: new Date(),
        updated_at: new Date(),
        tags: [],
      };

      const res = await app.request('/sync/full', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          localItems: [localItem],
          lastSyncTimestamp: new Date(0).toISOString(),
        }),
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as SyncResponse;
      expect(json.success).toBe(true);
      expect(json.push?.itemsCreated).toBe(1);
      expect(json.pull).toBeDefined();
      expect(json.serverTimestamp).toBeDefined();
    });

    it('should return conflicts in full sync', async () => {
      // First create an item on server
      const serverItem = {
        id: 'item-fullconflict-1',
        user_id: testUserId,
        title: 'Server Item',
        item_type: 'task',
        status: 'inbox',
        priority: 1,
        created_at: new Date(),
        updated_at: new Date(),
        tags: [],
      };

      await app.request('/sync/push', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({ items: [serverItem] }),
      }, mockEnv);

      // Then try full sync with older local version
      const localItem = {
        ...serverItem,
        title: 'Older Local Item',
        updated_at: new Date(Date.now() - 86400000),
      };

      const res = await app.request('/sync/full', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          localItems: [localItem],
          lastSyncTimestamp: new Date(0).toISOString(),
        }),
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as SyncResponse;
      expect(json.conflicts?.length).toBeGreaterThan(0);
    });
  });

  describe('GET /sync/status', () => {
    it('should return sync status', async () => {
      const res = await app.request('/sync/status', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
        },
      }, mockEnv);

      expect(res.status).toBe(200);
      const json = await res.json() as SyncResponse;
      expect(json.userId).toBe(testUserId);
      expect(json.itemCount).toBe(0);
      expect(json.memoryCount).toBe(0);
      expect(json.serverTime).toBeDefined();
    });

    it('should require authentication', async () => {
      const res = await app.request('/sync/status', {
        method: 'GET',
      }, mockEnv);

      expect(res.status).toBe(401);
    });
  });
});
