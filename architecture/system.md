# System Architecture

**Stage:** 4
**Status:** Complete
**Date:** 2026-01-15

---

## Overview

Jarvis is a native Apple platform application (iOS + macOS) with a cloud backend for AI processing and sync.

```
┌─────────────────────────────────────────────────────────────┐
│                      CLIENT LAYER                            │
│  ┌──────────────┐                    ┌──────────────┐       │
│  │   iOS App    │   ←── Sync ───→   │  macOS App   │       │
│  │  (SwiftUI)   │                    │  (SwiftUI)   │       │
│  └──────────────┘                    └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    API GATEWAY LAYER                         │
│              (REST API + WebSocket)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │   AI    │  │  Sync   │  │ Email   │  │Calendar │        │
│  │ Service │  │ Service │  │ Service │  │ Service │        │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   PostgreSQL │    │    Redis     │    │  S3/R2       │  │
│  │  (Primary)   │    │   (Cache)    │    │  (Files)     │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Client Architecture

### iOS App
- **Framework:** SwiftUI + Combine
- **Local Storage:** CoreData + CloudKit
- **Voice:** Speech framework + AVFoundation
- **Notifications:** UserNotifications framework

### macOS App
- **Framework:** SwiftUI + AppKit (where needed)
- **Shared Code:** 80%+ shared with iOS via targets
- **Menu Bar:** Native menu bar integration
- **Shortcuts:** Keyboard shortcuts support

### Sync Strategy
- **Primary:** CloudKit for user data
- **Fallback:** Custom sync service for conflict resolution
- **Offline:** Full functionality with local-first design

---

## Backend Architecture

### API Gateway
- **Technology:** Node.js + Express (or Cloudflare Workers)
- **Auth:** JWT tokens with refresh rotation
- **Rate Limiting:** Per-user, per-endpoint limits

### AI Service
- **Primary:** Claude API (Anthropic)
- **Fallback:** OpenAI GPT-4 API
- **Caching:** Response caching for common patterns
- **Streaming:** Server-sent events for real-time responses

### Integration Services
- **Email:** Gmail API, Apple Mail (via CloudKit)
- **Calendar:** Google Calendar API, EventKit
- **Queuing:** Redis-based job queue for async operations

---

## Component Interaction

```
Voice Command Flow:
1. iOS/macOS captures audio → Speech framework
2. Transcription → Local processing
3. Intent classification → Send to AI Service
4. AI generates response/action → Stream back
5. Client executes action → Update local state
6. Sync to cloud → Other devices update
```

---

## Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| iOS/macOS | SwiftUI | Native performance, Apple integration |
| Backend | Node.js/Cloudflare Workers | Fast, scalable, cost-effective |
| Database | PostgreSQL | Reliable, powerful querying |
| Cache | Redis | Fast, pub/sub support |
| AI | Claude API | Quality, speed, tool use |
| Auth | Auth0/Custom JWT | Proven security |
| File Storage | Cloudflare R2 | Cost-effective, S3-compatible |
