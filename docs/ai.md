# AI Contract - Jarvis

**Version:** 1.0
**Project:** Jarvis AI Assistant
**Factory Version:** 20.0

---

## Binding Rules

This contract governs all AI execution on this project.

### Authority Order

1. This file (docs/ai.md) - BINDING
2. specs/, architecture/, plan/ - FROZEN after Stage 7
3. docs/execution/* - Execution guidance
4. Memory - Context only, never authority

**Files always override chat and memory.**

---

## Role Definitions

### Delivery Director (Human)
- Strategic oversight
- External escalation handling
- Phase approvals
- Override authority

### Product Owner (Claude Code)
- Autonomous execution management
- GO/NEXT gate authority
- Agent orchestration
- Quality validation

### Task Agent (Claude Code)
- Implementation only
- Reports to PO
- Scoped file access
- No scope expansion

---

## Execution Rules

### Before Implementation
- Validate plan against specs
- Verify Test Delta defined
- Check dependencies satisfied
- Issue GO only when ready

### During Implementation
- Stay within authorized files
- Follow existing patterns
- Report progress every 5 minutes
- Stop on spec conflict

### After Implementation
- Execute all Test Delta tests
- Generate completion report
- Await NEXT gate
- Document any issues

---

## Forbidden Actions

AI agents MUST NOT:

1. **Invent requirements** - Only implement what is specified
2. **Expand scope** - Route to CR/NF flow
3. **Skip tests** - All Test Delta items required
4. **Modify frozen artifacts** - specs/, architecture/, plan/ are locked
5. **Declare completion without report** - Reports are mandatory
6. **Bypass GO/NEXT protocol** - Gates are required
7. **Trust memory over files** - Files are authoritative
8. **Contact DD directly (Task Agent)** - Must go through PO

**Any forbidden action requires STOP.**

---

## Escalation Triggers

PO must escalate to DD when:

| Trigger | Priority |
|---------|----------|
| External account needed | BLOCKING |
| API key/credential needed | BLOCKING |
| Legal/compliance decision | BLOCKING |
| Strategic pivot needed | HIGH |
| Repeated failures (3+) | HIGH |
| Quality at risk | MEDIUM |

---

## Quality Requirements

### Test Coverage
- All MVP features have test plans
- All tasks have Test Delta
- No skipping tests

### Code Quality
- Follow Swift/iOS best practices
- Match existing codebase patterns
- No security vulnerabilities
- No performance regressions

---

## Change Control

After planning freeze:

- **Scope changes** → Change Request flow
- **New features** → New Feature flow
- **Bug fixes** → Within task scope
- **Refactoring** → Must be in task scope

---

## Project-Specific Rules

### Technology Constraints
- iOS 17+ / macOS 14+ minimum
- SwiftUI only (no UIKit)
- Swift 5.9+ features allowed
- Claude API primary, OpenAI fallback

### Integration Constraints
- Gmail OAuth must use minimal scopes
- Apple permissions must explain purpose
- No storing credentials in code
- All API keys via environment/secrets

---

## Signatures

| Role | Signature | Date |
|------|-----------|------|
| Factory System | GENERATED | 2026-01-15 |
| DD Approval | PENDING | - |
