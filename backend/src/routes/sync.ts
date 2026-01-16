import { Hono } from 'hono';
import { authMiddleware } from '../middleware/auth';
import { JWTPayload } from '../utils/jwt';
import { getDb, SyncPayload, DbItem, DbMemory } from '../db';

interface Env {
  ENVIRONMENT: string;
  JWT_SECRET?: string;
}

type Variables = {
  user: JWTPayload;
};

export const syncRoutes = new Hono<{ Bindings: Env; Variables: Variables }>();

// All sync routes require authentication
syncRoutes.use('/*', authMiddleware);

/**
 * POST /sync/pull
 * Pull changes from server since last sync
 */
syncRoutes.post('/pull', async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{ lastSyncTimestamp?: string; deviceId?: string }>();
  const lastSync = body.lastSyncTimestamp ? new Date(body.lastSyncTimestamp) : new Date(0);

  const db = getDb();

  // Get items updated since last sync
  const allItems = await db.getItemsByUser(user.sub);
  const changedItems = allItems.filter(item => item.updated_at > lastSync);

  // Get memories updated since last sync
  const allMemories = await db.getMemoriesByUser(user.sub);
  const changedMemories = allMemories.filter(memory => memory.updated_at > lastSync);

  const payload: SyncPayload = {
    items: changedItems,
    memories: changedMemories,
    lastSyncTimestamp: new Date().toISOString(),
  };

  return c.json(payload);
});

/**
 * POST /sync/push
 * Push local changes to server
 */
syncRoutes.post('/push', async (c) => {
  const user = c.get('user');
  const body = await c.req.json<SyncPayload>();

  const db = getDb();
  const results = {
    itemsCreated: 0,
    itemsUpdated: 0,
    memoriesCreated: 0,
    memoriesUpdated: 0,
    conflicts: [] as Array<{ id: string; type: string; serverVersion: Date }>,
  };

  // Process items
  if (body.items) {
    for (const item of body.items) {
      // Verify ownership
      if (item.user_id !== user.sub) continue;

      const existing = await db.getItemById(item.id);
      if (existing) {
        // Check for conflict (server version is newer)
        if (existing.updated_at > item.updated_at) {
          results.conflicts.push({
            id: item.id,
            type: 'item',
            serverVersion: existing.updated_at,
          });
          continue;
        }
        await db.updateItem(item.id, item);
        results.itemsUpdated++;
      } else {
        await db.createItem(item);
        results.itemsCreated++;
      }
    }
  }

  // Process memories
  if (body.memories) {
    for (const memory of body.memories) {
      // Verify ownership
      if (memory.user_id !== user.sub) continue;

      const existing = await db.getMemoryById(memory.id);
      if (existing) {
        if (existing.updated_at > memory.updated_at) {
          results.conflicts.push({
            id: memory.id,
            type: 'memory',
            serverVersion: existing.updated_at,
          });
          continue;
        }
        await db.updateMemory(memory.id, memory);
        results.memoriesUpdated++;
      } else {
        await db.createMemory(memory);
        results.memoriesCreated++;
      }
    }
  }

  // Process deletions
  if (body.deletedIds) {
    if (body.deletedIds.items) {
      for (const id of body.deletedIds.items) {
        await db.deleteItem(id);
      }
    }
    if (body.deletedIds.memories) {
      for (const id of body.deletedIds.memories) {
        // Soft delete for memories would need implementation
      }
    }
  }

  return c.json({
    success: true,
    results,
    serverTimestamp: new Date().toISOString(),
  });
});

/**
 * POST /sync/full
 * Full bi-directional sync
 */
syncRoutes.post('/full', async (c) => {
  const user = c.get('user');
  const body = await c.req.json<{
    lastSyncTimestamp?: string;
    localItems?: DbItem[];
    localMemories?: DbMemory[];
    deletedIds?: { items?: string[]; memories?: string[] };
  }>();

  const lastSync = body.lastSyncTimestamp ? new Date(body.lastSyncTimestamp) : new Date(0);
  const db = getDb();

  // First, push local changes
  const pushResults = {
    itemsCreated: 0,
    itemsUpdated: 0,
    memoriesCreated: 0,
    memoriesUpdated: 0,
    conflicts: [] as Array<{ id: string; type: string; localVersion: Date; serverVersion: Date }>,
  };

  // Process local items
  if (body.localItems) {
    for (const item of body.localItems) {
      if (item.user_id !== user.sub) continue;

      const existing = await db.getItemById(item.id);
      if (existing) {
        if (existing.updated_at > item.updated_at) {
          pushResults.conflicts.push({
            id: item.id,
            type: 'item',
            localVersion: item.updated_at,
            serverVersion: existing.updated_at,
          });
          continue;
        }
        await db.updateItem(item.id, item);
        pushResults.itemsUpdated++;
      } else {
        await db.createItem(item);
        pushResults.itemsCreated++;
      }
    }
  }

  // Process local memories
  if (body.localMemories) {
    for (const memory of body.localMemories) {
      if (memory.user_id !== user.sub) continue;

      const existing = await db.getMemoryById(memory.id);
      if (existing) {
        if (existing.updated_at > memory.updated_at) {
          pushResults.conflicts.push({
            id: memory.id,
            type: 'memory',
            localVersion: memory.updated_at,
            serverVersion: existing.updated_at,
          });
          continue;
        }
        await db.updateMemory(memory.id, memory);
        pushResults.memoriesUpdated++;
      } else {
        await db.createMemory(memory);
        pushResults.memoriesCreated++;
      }
    }
  }

  // Process deletions
  if (body.deletedIds?.items) {
    for (const id of body.deletedIds.items) {
      await db.deleteItem(id);
    }
  }

  // Then, pull server changes
  const allItems = await db.getItemsByUser(user.sub);
  const serverItems = allItems.filter(item => item.updated_at > lastSync);

  const allMemories = await db.getMemoriesByUser(user.sub);
  const serverMemories = allMemories.filter(memory => memory.updated_at > lastSync);

  return c.json({
    success: true,
    push: pushResults,
    pull: {
      items: serverItems,
      memories: serverMemories,
    },
    conflicts: pushResults.conflicts,
    serverTimestamp: new Date().toISOString(),
  });
});

/**
 * GET /sync/status
 * Get current sync status for user
 */
syncRoutes.get('/status', async (c) => {
  const user = c.get('user');
  const db = getDb();

  const items = await db.getItemsByUser(user.sub);
  const memories = await db.getMemoriesByUser(user.sub);

  return c.json({
    userId: user.sub,
    itemCount: items.length,
    memoryCount: memories.length,
    serverTime: new Date().toISOString(),
  });
});
