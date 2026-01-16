import { describe, it, expect, beforeEach } from 'vitest';
import { InMemoryDb, DbUser, DbItem, DbMemory, DbAction } from '../src/db';

describe('InMemoryDb', () => {
  let db: InMemoryDb;

  beforeEach(() => {
    db = new InMemoryDb();
  });

  // ============================================
  // User Tests
  // ============================================
  describe('User operations', () => {
    const createTestUser = (): DbUser => ({
      id: 'user-1',
      email: 'test@example.com',
      display_name: 'Test User',
      avatar_url: null,
      password_hash: 'hash123',
      preferences: { notificationsEnabled: true, theme: 'system' },
      created_at: new Date(),
      updated_at: new Date(),
      last_synced_at: null,
      deleted_at: null,
    });

    it('should create and retrieve a user', async () => {
      const user = createTestUser();
      await db.createUser(user);

      const retrieved = await db.getUserById('user-1');
      expect(retrieved).not.toBeNull();
      expect(retrieved?.email).toBe('test@example.com');
    });

    it('should find user by email', async () => {
      const user = createTestUser();
      await db.createUser(user);

      const retrieved = await db.getUserByEmail('test@example.com');
      expect(retrieved).not.toBeNull();
      expect(retrieved?.id).toBe('user-1');
    });

    it('should return null for non-existent user', async () => {
      const retrieved = await db.getUserById('non-existent');
      expect(retrieved).toBeNull();
    });

    it('should update user', async () => {
      const user = createTestUser();
      await db.createUser(user);

      const updated = await db.updateUser('user-1', { display_name: 'New Name' });
      expect(updated?.display_name).toBe('New Name');
    });
  });

  // ============================================
  // Item Tests
  // ============================================
  describe('Item operations', () => {
    const createTestItem = (overrides?: Partial<DbItem>): DbItem => ({
      id: `item-${Math.random()}`,
      user_id: 'user-1',
      title: 'Test Item',
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
      ...overrides,
    });

    it('should create and retrieve an item', async () => {
      const item = createTestItem({ id: 'item-1' });
      await db.createItem(item);

      const retrieved = await db.getItemById('item-1');
      expect(retrieved).not.toBeNull();
      expect(retrieved?.title).toBe('Test Item');
    });

    it('should get items by user', async () => {
      await db.createItem(createTestItem({ id: 'item-1', user_id: 'user-1' }));
      await db.createItem(createTestItem({ id: 'item-2', user_id: 'user-1' }));
      await db.createItem(createTestItem({ id: 'item-3', user_id: 'user-2' }));

      const items = await db.getItemsByUser('user-1');
      expect(items.length).toBe(2);
    });

    it('should filter items by status', async () => {
      await db.createItem(createTestItem({ id: 'item-1', status: 'inbox' }));
      await db.createItem(createTestItem({ id: 'item-2', status: 'today' }));
      await db.createItem(createTestItem({ id: 'item-3', status: 'inbox' }));

      const items = await db.getItemsByUser('user-1', { status: 'inbox' });
      expect(items.length).toBe(2);
    });

    it('should filter items by tags', async () => {
      await db.createItem(createTestItem({ id: 'item-1', tags: ['work', 'urgent'] }));
      await db.createItem(createTestItem({ id: 'item-2', tags: ['personal'] }));
      await db.createItem(createTestItem({ id: 'item-3', tags: ['work'] }));

      const items = await db.getItemsByUser('user-1', { tags: ['work'] });
      expect(items.length).toBe(2);
    });

    it('should soft delete items', async () => {
      await db.createItem(createTestItem({ id: 'item-1' }));

      const deleted = await db.deleteItem('item-1');
      expect(deleted).toBe(true);

      const items = await db.getItemsByUser('user-1');
      expect(items.length).toBe(0);
    });

    it('should update items', async () => {
      await db.createItem(createTestItem({ id: 'item-1' }));

      const updated = await db.updateItem('item-1', { title: 'Updated Title', status: 'today' });
      expect(updated?.title).toBe('Updated Title');
      expect(updated?.status).toBe('today');
    });
  });

  // ============================================
  // Memory Tests
  // ============================================
  describe('Memory operations', () => {
    const createTestMemory = (overrides?: Partial<DbMemory>): DbMemory => ({
      id: `memory-${Math.random()}`,
      user_id: 'user-1',
      content: 'Test memory content',
      memory_type: 'fact',
      category: 'general',
      confidence: 1.0,
      source: 'explicit',
      related_item_ids: [],
      embedding: null,
      created_at: new Date(),
      updated_at: new Date(),
      last_accessed_at: null,
      access_count: 0,
      is_active: true,
      deleted_at: null,
      ...overrides,
    });

    it('should create and retrieve a memory', async () => {
      const memory = createTestMemory({ id: 'memory-1' });
      await db.createMemory(memory);

      const retrieved = await db.getMemoryById('memory-1');
      expect(retrieved).not.toBeNull();
      expect(retrieved?.content).toBe('Test memory content');
    });

    it('should get memories by user', async () => {
      await db.createMemory(createTestMemory({ id: 'memory-1', user_id: 'user-1' }));
      await db.createMemory(createTestMemory({ id: 'memory-2', user_id: 'user-1' }));
      await db.createMemory(createTestMemory({ id: 'memory-3', user_id: 'user-2' }));

      const memories = await db.getMemoriesByUser('user-1');
      expect(memories.length).toBe(2);
    });

    it('should filter memories by category', async () => {
      await db.createMemory(createTestMemory({ id: 'memory-1', category: 'work' }));
      await db.createMemory(createTestMemory({ id: 'memory-2', category: 'personal' }));

      const memories = await db.getMemoriesByUser('user-1', { category: 'work' });
      expect(memories.length).toBe(1);
    });

    it('should filter active memories', async () => {
      await db.createMemory(createTestMemory({ id: 'memory-1', is_active: true }));
      await db.createMemory(createTestMemory({ id: 'memory-2', is_active: false }));

      const memories = await db.getMemoriesByUser('user-1', { isActive: true });
      expect(memories.length).toBe(1);
    });

    it('should search memories by content', async () => {
      await db.createMemory(createTestMemory({ id: 'memory-1', content: 'User likes morning meetings' }));
      await db.createMemory(createTestMemory({ id: 'memory-2', content: 'User prefers dark mode' }));

      const memories = await db.getMemoriesByUser('user-1', { search: 'morning' });
      expect(memories.length).toBe(1);
      expect(memories[0].content).toContain('morning');
    });
  });

  // ============================================
  // Action Tests
  // ============================================
  describe('Action operations', () => {
    const createTestAction = (overrides?: Partial<DbAction>): DbAction => ({
      id: `action-${Math.random()}`,
      user_id: 'user-1',
      action_type: 'create',
      target_type: 'item',
      target_id: null,
      description: 'Test action',
      metadata: {},
      timestamp: new Date(),
      device_id: null,
      session_id: null,
      ...overrides,
    });

    it('should create and retrieve actions', async () => {
      const action = createTestAction({ id: 'action-1' });
      await db.createAction(action);

      const actions = await db.getActionsByUser('user-1');
      expect(actions.length).toBe(1);
    });

    it('should filter actions by type', async () => {
      await db.createAction(createTestAction({ id: 'action-1', action_type: 'create' }));
      await db.createAction(createTestAction({ id: 'action-2', action_type: 'complete' }));
      await db.createAction(createTestAction({ id: 'action-3', action_type: 'create' }));

      const actions = await db.getActionsByUser('user-1', { actionTypes: ['create'] });
      expect(actions.length).toBe(2);
    });

    it('should filter actions by date range', async () => {
      const now = new Date();
      const yesterday = new Date(now.getTime() - 86400000);
      const tomorrow = new Date(now.getTime() + 86400000);

      await db.createAction(createTestAction({ id: 'action-1', timestamp: yesterday }));
      await db.createAction(createTestAction({ id: 'action-2', timestamp: now }));
      await db.createAction(createTestAction({ id: 'action-3', timestamp: tomorrow }));

      const actions = await db.getActionsByUser('user-1', {
        startDate: new Date(now.getTime() - 3600000),
        endDate: new Date(now.getTime() + 3600000),
      });
      expect(actions.length).toBe(1);
    });

    it('should limit action results', async () => {
      for (let i = 0; i < 10; i++) {
        await db.createAction(createTestAction({ id: `action-${i}` }));
      }

      const actions = await db.getActionsByUser('user-1', { limit: 5 });
      expect(actions.length).toBe(5);
    });
  });

  // ============================================
  // Utility Tests
  // ============================================
  describe('Utility operations', () => {
    it('should clear all data', async () => {
      await db.createUser({
        id: 'user-1',
        email: 'test@example.com',
        display_name: null,
        avatar_url: null,
        password_hash: 'hash',
        preferences: { notificationsEnabled: true, theme: 'system' },
        created_at: new Date(),
        updated_at: new Date(),
        last_synced_at: null,
        deleted_at: null,
      });

      db.clear();

      const user = await db.getUserById('user-1');
      expect(user).toBeNull();
    });
  });
});
