# F-005: Daily Planning

**Priority:** P0 (MVP)
**Status:** Specified

---

## Acceptance Criteria

### AC-001: Morning Plan Generation
- GIVEN user asks "What matters today?"
- THEN Jarvis presents 3-5 top outcomes with time blocks

### AC-002: Calendar Integration
- GIVEN events exist on calendar
- WHEN plan is generated
- THEN events are incorporated into the plan

### AC-003: Priority Ranking
- GIVEN multiple items compete for attention
- WHEN plan is presented
- THEN items are ranked by urgency and importance

### AC-004: Overload Detection
- GIVEN planned items exceed available time
- WHEN plan is presented
- THEN warning shows with suggested tradeoffs

### AC-005: Plan Modification
- GIVEN a plan exists
- WHEN user requests change
- THEN plan updates and recalculates

### AC-006: Time Block Suggestions
- GIVEN tasks need focus time
- WHEN generating plan
- THEN specific time blocks are suggested

### AC-007: Plan Persistence
- GIVEN plan is accepted
- THEN plan is saved and trackable throughout day

---

## Dependencies

- F-001: Unified Inbox (task sources)
- F-004: Calendar Integration (schedule awareness)
