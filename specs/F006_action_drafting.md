# F-006: Action Drafting

**Priority:** P0 (MVP)
**Status:** Specified

---

## Acceptance Criteria

### AC-001: Email Draft Generation
- GIVEN user requests email draft
- WHEN context and intent provided
- THEN draft is generated matching user's writing style

### AC-002: Tone Adaptation
- GIVEN user specifies tone (friendly, formal, brief)
- WHEN generating draft
- THEN output matches requested tone

### AC-003: Context Incorporation
- GIVEN prior conversation exists
- WHEN drafting reply
- THEN draft incorporates relevant context

### AC-004: Draft Review
- GIVEN draft is generated
- WHEN presented to user
- THEN user can edit, approve, or regenerate

### AC-005: Learning from Edits
- GIVEN user edits a draft
- WHEN saved
- THEN edits inform future draft generation

### AC-006: Quick Commands
- GIVEN shorthand like "reply yes, push to next week"
- WHEN processing
- THEN full professional draft is generated

### AC-007: Multiple Draft Options
- GIVEN complex request
- WHEN user asks
- THEN 2-3 draft variations are offered

---

## Dependencies

- F-008: Memory System (writing style, preferences)
