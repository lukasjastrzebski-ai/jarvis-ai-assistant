-- Jarvis AI Assistant Database Schema
-- PostgreSQL compatible schema for cloud storage
-- Version: 1.0.0

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";

-- ============================================
-- Users Table
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255),
    avatar_url TEXT,
    password_hash VARCHAR(255) NOT NULL,
    preferences JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_synced_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_updated_at ON users(updated_at);

-- ============================================
-- Items Table (Tasks, Notes, Events, etc.)
-- ============================================
CREATE TABLE items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    content TEXT,
    item_type VARCHAR(50) NOT NULL DEFAULT 'task',
    status VARCHAR(50) NOT NULL DEFAULT 'inbox',
    priority INTEGER NOT NULL DEFAULT 1,
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tags TEXT[] DEFAULT '{}',
    parent_id UUID REFERENCES items(id) ON DELETE SET NULL,
    source_id VARCHAR(255),
    source_type VARCHAR(50),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT valid_item_type CHECK (item_type IN ('task', 'note', 'event', 'reminder', 'reference')),
    CONSTRAINT valid_status CHECK (status IN ('inbox', 'today', 'scheduled', 'someday', 'completed', 'archived')),
    CONSTRAINT valid_priority CHECK (priority >= 0 AND priority <= 3)
);

CREATE INDEX idx_items_user_id ON items(user_id);
CREATE INDEX idx_items_status ON items(status);
CREATE INDEX idx_items_due_date ON items(due_date);
CREATE INDEX idx_items_updated_at ON items(updated_at);
CREATE INDEX idx_items_tags ON items USING GIN(tags);
CREATE INDEX idx_items_user_status ON items(user_id, status);

-- ============================================
-- Memories Table (User context and preferences)
-- ============================================
CREATE TABLE memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    memory_type VARCHAR(50) NOT NULL DEFAULT 'fact',
    category VARCHAR(50) NOT NULL DEFAULT 'general',
    confidence DECIMAL(3,2) NOT NULL DEFAULT 1.0,
    source VARCHAR(50) NOT NULL DEFAULT 'explicit',
    related_item_ids UUID[] DEFAULT '{}',
    embedding vector(1536), -- OpenAI ada-002 dimension
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ,
    access_count INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    deleted_at TIMESTAMPTZ,

    CONSTRAINT valid_memory_type CHECK (memory_type IN ('fact', 'preference', 'context', 'routine', 'relationship')),
    CONSTRAINT valid_category CHECK (category IN ('general', 'work', 'personal', 'health', 'finance', 'travel', 'social', 'learning')),
    CONSTRAINT valid_source CHECK (source IN ('explicit', 'inferred', 'imported', 'corrected')),
    CONSTRAINT valid_confidence CHECK (confidence >= 0 AND confidence <= 1)
);

CREATE INDEX idx_memories_user_id ON memories(user_id);
CREATE INDEX idx_memories_category ON memories(category);
CREATE INDEX idx_memories_is_active ON memories(is_active);
CREATE INDEX idx_memories_updated_at ON memories(updated_at);
-- Vector similarity index for semantic search
CREATE INDEX idx_memories_embedding ON memories USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- ============================================
-- Actions Table (Activity Log)
-- ============================================
CREATE TABLE actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id UUID,
    description TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    device_id VARCHAR(255),
    session_id UUID,

    CONSTRAINT valid_action_type CHECK (action_type IN (
        'create', 'read', 'update', 'delete',
        'complete', 'uncomplete', 'archive', 'restore',
        'schedule', 'reschedule', 'prioritize', 'tag', 'untag',
        'view', 'search', 'filter',
        'sync', 'login', 'logout', 'settingsChange'
    )),
    CONSTRAINT valid_target_type CHECK (target_type IN ('item', 'memory', 'user', 'calendar', 'settings', 'system'))
);

CREATE INDEX idx_actions_user_id ON actions(user_id);
CREATE INDEX idx_actions_timestamp ON actions(timestamp DESC);
CREATE INDEX idx_actions_target ON actions(target_type, target_id);
CREATE INDEX idx_actions_user_timestamp ON actions(user_id, timestamp DESC);

-- ============================================
-- Refresh Tokens Table (for JWT auth)
-- ============================================
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    device_info JSONB,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- ============================================
-- Sync State Table (for tracking client sync)
-- ============================================
CREATE TABLE sync_state (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    last_sync_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sync_cursor TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(user_id, device_id)
);

CREATE INDEX idx_sync_state_user_device ON sync_state(user_id, device_id);

-- ============================================
-- Functions and Triggers
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER items_updated_at
    BEFORE UPDATE ON items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER memories_updated_at
    BEFORE UPDATE ON memories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- Views
-- ============================================

-- Active items view (excludes deleted/archived)
CREATE VIEW active_items AS
SELECT * FROM items
WHERE deleted_at IS NULL AND status != 'archived';

-- Active memories view
CREATE VIEW active_memories AS
SELECT * FROM memories
WHERE deleted_at IS NULL AND is_active = true;

-- Today's items view
CREATE VIEW today_items AS
SELECT * FROM items
WHERE deleted_at IS NULL
  AND (status = 'today' OR (due_date IS NOT NULL AND due_date::date = CURRENT_DATE));
