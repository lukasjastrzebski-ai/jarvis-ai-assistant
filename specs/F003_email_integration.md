# F-003: Email Integration

**Priority:** P0 (MVP)
**Status:** Specified
**Owner:** TBD

---

## Description

Email Integration connects Jarvis to user's email accounts, enabling read, draft, send, and organize capabilities.

---

## Acceptance Criteria

### AC-001: Account Connection (Gmail)
- GIVEN user wants to connect Gmail
- WHEN they complete OAuth flow
- THEN emails sync to Unified Inbox within 2 minutes

### AC-002: Account Connection (Apple Mail)
- GIVEN user wants to connect Apple Mail
- WHEN they grant permissions
- THEN emails sync to Unified Inbox within 2 minutes

### AC-003: Email Reading
- GIVEN emails are synced
- WHEN user opens an email
- THEN full content displays with attachments listed

### AC-004: Email Drafting
- GIVEN user requests a draft
- WHEN Jarvis generates draft
- THEN draft appears for review before sending

### AC-005: Email Sending
- GIVEN a draft is approved
- WHEN user confirms send
- THEN email is sent and appears in Sent folder

### AC-006: Email Archiving
- GIVEN an email is in inbox
- WHEN user archives it
- THEN email moves to archive/all mail

### AC-007: Thread Handling
- GIVEN an email is part of a thread
- WHEN displayed
- THEN full thread context is available

### AC-008: Real-time Sync
- GIVEN a new email arrives
- WHEN sync occurs
- THEN email appears in Unified Inbox within 30 seconds

---

## Technical Requirements

- Gmail API integration (OAuth 2.0)
- Apple Mail integration (system permissions)
- IMAP fallback for other providers (future)
- Offline draft storage
- Attachment handling up to 25MB

---

## Dependencies

- F-001: Unified Inbox (display layer)
- F-006: Action Drafting (draft generation)

---

## Test Plan Reference

See: specs/tests/F003_email_integration_test.md
