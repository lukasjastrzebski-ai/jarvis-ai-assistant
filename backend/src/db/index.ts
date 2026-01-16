/**
 * Database module exports
 */

export * from './types';

/**
 * In-memory database for development/testing
 * In production, this would be replaced with actual PostgreSQL connections
 */
export class InMemoryDb {
  private users: Map<string, import('./types').DbUser> = new Map();
  private items: Map<string, import('./types').DbItem> = new Map();
  private memories: Map<string, import('./types').DbMemory> = new Map();
  private actions: Map<string, import('./types').DbAction> = new Map();

  // User operations
  async createUser(user: import('./types').DbUser): Promise<import('./types').DbUser> {
    this.users.set(user.id, user);
    return user;
  }

  async getUserById(id: string): Promise<import('./types').DbUser | null> {
    return this.users.get(id) || null;
  }

  async getUserByEmail(email: string): Promise<import('./types').DbUser | null> {
    for (const user of this.users.values()) {
      if (user.email === email) return user;
    }
    return null;
  }

  async updateUser(id: string, updates: Partial<import('./types').DbUser>): Promise<import('./types').DbUser | null> {
    const user = this.users.get(id);
    if (!user) return null;
    const updated = { ...user, ...updates, updated_at: new Date() };
    this.users.set(id, updated);
    return updated;
  }

  // Item operations
  async createItem(item: import('./types').DbItem): Promise<import('./types').DbItem> {
    this.items.set(item.id, item);
    return item;
  }

  async getItemById(id: string): Promise<import('./types').DbItem | null> {
    return this.items.get(id) || null;
  }

  async getItemsByUser(userId: string, query?: import('./types').ItemQuery): Promise<import('./types').DbItem[]> {
    let results = Array.from(this.items.values()).filter(
      item => item.user_id === userId && !item.deleted_at
    );

    if (query?.status) {
      results = results.filter(item => item.status === query.status);
    }
    if (query?.itemType) {
      results = results.filter(item => item.item_type === query.itemType);
    }
    if (query?.dueBefore) {
      results = results.filter(item => item.due_date && item.due_date < query.dueBefore!);
    }
    if (query?.tags?.length) {
      results = results.filter(item => query.tags!.some(tag => item.tags.includes(tag)));
    }

    results.sort((a, b) => b.updated_at.getTime() - a.updated_at.getTime());

    if (query?.offset) results = results.slice(query.offset);
    if (query?.limit) results = results.slice(0, query.limit);

    return results;
  }

  async updateItem(id: string, updates: Partial<import('./types').DbItem>): Promise<import('./types').DbItem | null> {
    const item = this.items.get(id);
    if (!item) return null;
    const updated = { ...item, ...updates, updated_at: new Date() };
    this.items.set(id, updated);
    return updated;
  }

  async deleteItem(id: string): Promise<boolean> {
    const item = this.items.get(id);
    if (!item) return false;
    item.deleted_at = new Date();
    return true;
  }

  // Memory operations
  async createMemory(memory: import('./types').DbMemory): Promise<import('./types').DbMemory> {
    this.memories.set(memory.id, memory);
    return memory;
  }

  async getMemoryById(id: string): Promise<import('./types').DbMemory | null> {
    return this.memories.get(id) || null;
  }

  async getMemoriesByUser(userId: string, query?: import('./types').MemoryQuery): Promise<import('./types').DbMemory[]> {
    let results = Array.from(this.memories.values()).filter(
      memory => memory.user_id === userId && !memory.deleted_at
    );

    if (query?.category) {
      results = results.filter(m => m.category === query.category);
    }
    if (query?.memoryType) {
      results = results.filter(m => m.memory_type === query.memoryType);
    }
    if (query?.isActive !== undefined) {
      results = results.filter(m => m.is_active === query.isActive);
    }
    if (query?.search) {
      const searchLower = query.search.toLowerCase();
      results = results.filter(m => m.content.toLowerCase().includes(searchLower));
    }

    results.sort((a, b) => b.updated_at.getTime() - a.updated_at.getTime());

    if (query?.offset) results = results.slice(query.offset);
    if (query?.limit) results = results.slice(0, query.limit);

    return results;
  }

  async updateMemory(id: string, updates: Partial<import('./types').DbMemory>): Promise<import('./types').DbMemory | null> {
    const memory = this.memories.get(id);
    if (!memory) return null;
    const updated = { ...memory, ...updates, updated_at: new Date() };
    this.memories.set(id, updated);
    return updated;
  }

  // Action operations
  async createAction(action: import('./types').DbAction): Promise<import('./types').DbAction> {
    this.actions.set(action.id, action);
    return action;
  }

  async getActionsByUser(userId: string, query?: import('./types').ActionQuery): Promise<import('./types').DbAction[]> {
    let results = Array.from(this.actions.values()).filter(
      action => action.user_id === userId
    );

    if (query?.actionTypes?.length) {
      results = results.filter(a => query.actionTypes!.includes(a.action_type));
    }
    if (query?.targetTypes?.length) {
      results = results.filter(a => query.targetTypes!.includes(a.target_type));
    }
    if (query?.targetId) {
      results = results.filter(a => a.target_id === query.targetId);
    }
    if (query?.startDate) {
      results = results.filter(a => a.timestamp >= query.startDate!);
    }
    if (query?.endDate) {
      results = results.filter(a => a.timestamp <= query.endDate!);
    }

    results.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());

    if (query?.offset) results = results.slice(query.offset);
    if (query?.limit) results = results.slice(0, query.limit);

    return results;
  }

  // Utility methods
  clear(): void {
    this.users.clear();
    this.items.clear();
    this.memories.clear();
    this.actions.clear();
  }
}

// Singleton instance for the application
let dbInstance: InMemoryDb | null = null;

export function getDb(): InMemoryDb {
  if (!dbInstance) {
    dbInstance = new InMemoryDb();
  }
  return dbInstance;
}

export function resetDb(): void {
  if (dbInstance) {
    dbInstance.clear();
  }
}
