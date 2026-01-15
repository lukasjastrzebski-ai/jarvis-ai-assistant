# F-001 Unified Inbox - Test Plan

## Unit Tests

| Test ID | Description | Input | Expected |
|---------|-------------|-------|----------|
| UI-001 | Item renders correctly | Mock email item | Shows sender, subject, time |
| UI-002 | Empty state shows | No items | Zero inbox message |
| UI-003 | Urgency badge displays | Urgent item | Red badge visible |
| UI-004 | Batch select works | Multi-select | All selected highlighted |

## Integration Tests

| Test ID | Description | Setup | Expected |
|---------|-------------|-------|----------|
| UI-101 | Email sync populates inbox | Gmail connected | Emails appear |
| UI-102 | Calendar items show | Calendar connected | Events in inbox |
| UI-103 | Archive moves item | Item in inbox | Item disappears, in archive |
| UI-104 | Snooze schedules return | Snooze 1 hour | Item returns after 1 hour |

## E2E Tests

| Test ID | Scenario | Steps | Expected |
|---------|----------|-------|----------|
| UI-201 | Morning triage | Connect email, open inbox, process 5 items | All items actioned |
| UI-202 | Batch archive | Select 3 newsletters, batch archive | All 3 archived |

## Performance Tests

| Test ID | Metric | Threshold |
|---------|--------|-----------|
| UI-301 | Inbox load time (100 items) | <2 seconds |
| UI-302 | Scroll FPS | >55 FPS |
