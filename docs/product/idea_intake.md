# Idea Intake

**Stage:** 0
**Status:** Complete
**Date:** 2026-01-15

---

## Problem Statement

Solo entrepreneurs are the router for everything in their business - every email, every decision, every task flows through them. This creates:

1. **Constant context switching** - bouncing between sales, product, operations, support
2. **Dropped balls** - things fall through the cracks when juggling too many threads
3. **Low throughput** - repetitive work consumes time that should go to high-leverage activities
4. **Poor decision hygiene** - no system to capture, track, and enforce priorities

Current "AI assistants" are smart speakers or chatbots - they answer questions but don't operate. They don't maintain context, don't take actions, and don't enforce boundaries.

---

## Target User

**Primary:** Solo entrepreneur running a business from iPhone + Mac

Profile:
- Technical founder or product-oriented business owner
- Manages 5-20+ active projects/clients
- Heavy email, calendar, task, and communication load
- Values deep work but constantly interrupted
- Already uses Apple ecosystem (Calendar, Mail, Reminders)
- Willing to pay for productivity tools that actually work

**Anti-user:**
- Large teams with dedicated admins
- Non-technical users who need hand-holding
- People who want general chat AI (that space is crowded)

---

## Why Now

1. **LLM capability maturity** - Claude/GPT-4 class models can now understand context, draft professionally, and reason about priorities
2. **Voice recognition quality** - Native speech recognition is good enough for reliable voice commands
3. **API ecosystem** - Major productivity tools have mature APIs for integration
4. **Market gap** - No voice-first AI chief of staff exists; Siri/Alexa are dumb, ChatGPT is chat-only
5. **Solo economy growth** - More people running businesses solo, needing leverage

---

## Assumptions

### Validated
- Solo entrepreneurs spend 40%+ time on coordination vs. creation
- Voice is faster than typing for capture and quick commands
- Unified inbox > multiple apps for triage

### To Validate
- Users will trust AI to draft emails (with approval flow)
- Users will pay $50-100/month for meaningful time savings
- Apple platform restrictions won't block core features
- Latency can be kept under 2 seconds for voice interactions

---

## Constraints

### Technical
- iOS + macOS only (Apple ecosystem)
- Voice interaction requires app to be active (no system-level Siri integration)
- iMessage API access is restricted by Apple
- Some integrations require OAuth which can be friction-heavy

### Business
- Bootstrap-funded, must reach profitability
- Cannot rely on viral growth, needs direct value proposition
- Privacy-first approach (competitive differentiator)

### Product
- Must not feel like "another app to check"
- Voice commands must be forgiving (natural language, not rigid syntax)
- Must earn trust gradually (assist → operate → autopilot)

---

## Open Questions

### Product
1. What's the minimum set of integrations for MVP?
2. How do we handle failures gracefully (wrong email sent, bad calendar entry)?
3. What's the right confirmation threshold per action type?

### Technical
1. On-device vs. cloud for AI inference?
2. How to handle offline mode?
3. Sync architecture for iPhone + Mac?

### Business
1. Freemium or paid-only?
2. What's the activation metric that predicts retention?
3. How to demonstrate value in free trial?

---

## Source Document

Original idea document: [docs/import/sources/app_idea.md](../import/sources/app_idea.md)
