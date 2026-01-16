/**
 * Database types for the Jarvis API
 */

// ============================================
// User Types
// ============================================

export interface DbUser {
  id: string;
  email: string;
  display_name: string | null;
  avatar_url: string | null;
  password_hash: string;
  preferences: UserPreferences;
  created_at: Date;
  updated_at: Date;
  last_synced_at: Date | null;
  deleted_at: Date | null;
}

export interface UserPreferences {
  notificationsEnabled: boolean;
  dailyDigestTime?: string;
  theme: 'light' | 'dark' | 'system';
  defaultCalendarId?: string;
}

// ============================================
// Item Types
// ============================================

export type ItemType = 'task' | 'note' | 'event' | 'reminder' | 'reference';
export type ItemStatus = 'inbox' | 'today' | 'scheduled' | 'someday' | 'completed' | 'archived';
export type Priority = 0 | 1 | 2 | 3;

export interface DbItem {
  id: string;
  user_id: string;
  title: string;
  content: string | null;
  item_type: ItemType;
  status: ItemStatus;
  priority: Priority;
  due_date: Date | null;
  completed_at: Date | null;
  created_at: Date;
  updated_at: Date;
  tags: string[];
  parent_id: string | null;
  source_id: string | null;
  source_type: string | null;
  deleted_at: Date | null;
}

// ============================================
// Memory Types
// ============================================

export type MemoryType = 'fact' | 'preference' | 'context' | 'routine' | 'relationship';
export type MemoryCategory = 'general' | 'work' | 'personal' | 'health' | 'finance' | 'travel' | 'social' | 'learning';
export type MemorySource = 'explicit' | 'inferred' | 'imported' | 'corrected';

export interface DbMemory {
  id: string;
  user_id: string;
  content: string;
  memory_type: MemoryType;
  category: MemoryCategory;
  confidence: number;
  source: MemorySource;
  related_item_ids: string[];
  embedding: number[] | null;
  created_at: Date;
  updated_at: Date;
  last_accessed_at: Date | null;
  access_count: number;
  is_active: boolean;
  deleted_at: Date | null;
}

// ============================================
// Action Types
// ============================================

export type ActionType =
  | 'create' | 'read' | 'update' | 'delete'
  | 'complete' | 'uncomplete' | 'archive' | 'restore'
  | 'schedule' | 'reschedule' | 'prioritize' | 'tag' | 'untag'
  | 'view' | 'search' | 'filter'
  | 'sync' | 'login' | 'logout' | 'settingsChange';

export type TargetType = 'item' | 'memory' | 'user' | 'calendar' | 'settings' | 'system';

export interface DbAction {
  id: string;
  user_id: string;
  action_type: ActionType;
  target_type: TargetType;
  target_id: string | null;
  description: string;
  metadata: Record<string, unknown>;
  timestamp: Date;
  device_id: string | null;
  session_id: string | null;
}

// ============================================
// Query Types
// ============================================

export interface ActionQuery {
  userId?: string;
  actionTypes?: ActionType[];
  targetTypes?: TargetType[];
  targetId?: string;
  startDate?: Date;
  endDate?: Date;
  limit?: number;
  offset?: number;
}

export interface ItemQuery {
  userId?: string;
  status?: ItemStatus;
  itemType?: ItemType;
  dueBefore?: Date;
  dueAfter?: Date;
  tags?: string[];
  search?: string;
  limit?: number;
  offset?: number;
}

export interface MemoryQuery {
  userId?: string;
  category?: MemoryCategory;
  memoryType?: MemoryType;
  isActive?: boolean;
  search?: string;
  limit?: number;
  offset?: number;
}

// ============================================
// Sync Types
// ============================================

export interface SyncState {
  id: string;
  user_id: string;
  device_id: string;
  last_sync_timestamp: Date;
  sync_cursor: string | null;
  created_at: Date;
}

export interface SyncPayload {
  items?: DbItem[];
  memories?: DbMemory[];
  deletedIds?: {
    items?: string[];
    memories?: string[];
  };
  lastSyncTimestamp: string;
}
