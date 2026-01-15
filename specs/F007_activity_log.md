# F-007: Activity Log

**Priority:** P0 (MVP)
**Status:** Specified

---

## Acceptance Criteria

### AC-001: Action Logging
- GIVEN Jarvis takes any action
- THEN action is logged with timestamp, type, and details

### AC-002: Log Accessibility
- GIVEN activity log exists
- WHEN user opens Activity view
- THEN all logged actions are visible chronologically

### AC-003: Action Details
- GIVEN a logged action
- WHEN user taps/clicks it
- THEN full details including "why" are shown

### AC-004: Undo Capability
- GIVEN a reversible action was taken
- WHEN user requests undo
- THEN action is reversed where possible

### AC-005: Filtering
- GIVEN many actions logged
- WHEN user applies filter (by type, date)
- THEN filtered view is shown

### AC-006: Explanation
- GIVEN an action was taken
- WHEN viewing details
- THEN explanation of Jarvis's reasoning is provided

### AC-007: Approval History
- GIVEN actions required approval
- THEN approval/rejection history is recorded

---

## Technical Requirements

- Persistent local storage
- Cloud backup of log
- Search within log
- Export capability
