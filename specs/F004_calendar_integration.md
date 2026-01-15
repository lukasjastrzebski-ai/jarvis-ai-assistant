# F-004: Calendar Integration

**Priority:** P0 (MVP)
**Status:** Specified

---

## Acceptance Criteria

### AC-001: Apple Calendar Connection
- GIVEN user grants calendar permissions
- WHEN sync completes
- THEN all calendar events appear in Jarvis

### AC-002: Google Calendar Connection
- GIVEN user completes Google OAuth
- WHEN sync completes
- THEN all calendar events appear in Jarvis

### AC-003: Event Display
- GIVEN events exist
- WHEN viewing daily plan
- THEN events show time, title, location, attendees

### AC-004: Event Creation
- GIVEN user requests new event
- WHEN confirmed
- THEN event appears on connected calendars

### AC-005: Conflict Detection
- GIVEN user creates overlapping event
- WHEN saving
- THEN warning shows with resolution options

### AC-006: Real-time Sync
- GIVEN calendar changes externally
- WHEN sync occurs
- THEN changes reflect within 60 seconds

### AC-007: Multi-Calendar Support
- GIVEN user has multiple calendars
- WHEN viewing schedule
- THEN all calendars are merged with color coding

---

## Dependencies

- F-001: Unified Inbox
- F-005: Daily Planning
