# Data Architecture

**Stage:** 4
**Status:** Complete
**Date:** 2026-01-15

---

## Data Model Overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    User      │────<│   Account    │────<│ Integration  │
└──────────────┘     └──────────────┘     └──────────────┘
       │
       │     ┌──────────────┐     ┌──────────────┐
       └────<│    Item      │────<│   Action     │
             └──────────────┘     └──────────────┘
       │
       │     ┌──────────────┐
       └────<│   Memory     │
             └──────────────┘
```

---

## Core Entities

### User
```json
{
  "id": "uuid",
  "email": "string",
  "name": "string",
  "created_at": "timestamp",
  "settings": {
    "operating_mode": "assist|operator|autopilot",
    "voice_enabled": "boolean",
    "timezone": "string"
  }
}
```

### Item (Unified Inbox)
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "source": "email|calendar|task|slack",
  "source_id": "string",
  "type": "incoming|created|generated",
  "title": "string",
  "content": "text",
  "sender": "string",
  "urgency": "urgent|today|this_week|later",
  "status": "active|snoozed|archived|actioned",
  "jarvis_suggestion": "json",
  "created_at": "timestamp",
  "snoozed_until": "timestamp|null"
}
```

### Memory
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "type": "person|project|rule|style|definition",
  "key": "string",
  "value": "json",
  "segment": "personal|work",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "embedding": "vector(1536)"
}
```

### Action (Activity Log)
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "type": "email_sent|event_created|task_added|...",
  "item_id": "uuid|null",
  "details": "json",
  "reasoning": "string",
  "approved_by": "user|auto",
  "reversible": "boolean",
  "reversed_at": "timestamp|null",
  "created_at": "timestamp"
}
```

---

## Storage Strategy

### Local (Device)
- CoreData for structured data
- File system for attachments
- Keychain for credentials
- UserDefaults for preferences

### Cloud
- PostgreSQL for relational data
- Redis for session/cache
- R2/S3 for file attachments
- Vector DB for memory embeddings

### Sync
- CloudKit for automatic Apple sync
- Custom sync for cross-platform
- Conflict resolution: last-write-wins with merge for complex types

---

## Data Flow

### Inbound (Email arrives)
1. Integration service polls/receives webhook
2. Email parsed and normalized to Item schema
3. Stored in PostgreSQL
4. Pushed to client via WebSocket
5. Client stores in CoreData
6. UI updates

### Outbound (Email sent)
1. Client creates draft Item
2. Synced to cloud
3. AI Service generates content
4. User approves
5. Email Service sends via Gmail API
6. Action logged
7. Item marked as actioned
