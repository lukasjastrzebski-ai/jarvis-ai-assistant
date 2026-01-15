# Non-Goals

**Stage:** 2
**Status:** Complete
**Date:** 2026-01-15

---

## Purpose

This document explicitly defines what Jarvis is NOT. These are not "future features" - they are deliberate exclusions that define our product.

---

## Platform Non-Goals

### NG-1: Android Support
**We will NOT build an Android app.**

Rationale:
- Apple ecosystem integration is core differentiator
- Splitting focus reduces quality
- Our target users are Apple-heavy
- Android users have different expectations

Review trigger: If >30% of waitlist requests Android.

---

### NG-2: Web Application
**We will NOT build a web app.**

Rationale:
- Native voice integration requires native apps
- Web reduces UX quality
- Sync complexity increases
- Not how our users work

Review trigger: Enterprise segment shows significant demand.

---

### NG-3: Windows/Linux Support
**We will NOT build desktop apps for Windows/Linux.**

Rationale:
- Same as Android - focus matters
- Cross-platform frameworks reduce quality
- Our users are Mac users

Review trigger: Never - this is permanent.

---

## Feature Non-Goals

### NG-4: Team Collaboration
**We will NOT build features for teams.**

Rationale:
- Solo entrepreneur is our user
- Team features require different architecture
- Enterprise sales cycle is different
- Different competitive landscape

Examples of excluded features:
- Shared inboxes
- Team calendars
- Permission hierarchies
- Admin consoles
- Team analytics

Review trigger: When we hit $5M ARR and consider segment expansion.

---

### NG-5: General AI Chat
**We will NOT be a general-purpose AI chatbot.**

Rationale:
- ChatGPT/Claude already do this well
- It's not our differentiation
- Users don't need another chatbot
- Dilutes operator positioning

Examples of excluded features:
- "Tell me a joke"
- "Explain quantum computing"
- General Q&A
- Creative writing prompts

Review trigger: Never - this is core positioning.

---

### NG-6: Automation Builder
**We will NOT let users build custom automations.**

Rationale:
- Zapier/Make already do this
- Building is not our value prop
- Complexity kills simplicity
- Maintenance burden on users

Examples of excluded features:
- If-this-then-that rules
- Custom trigger definitions
- Flow builders
- Scripting languages

What we DO instead:
- Pre-built workflows that work
- Jarvis learns preferences automatically
- Simple on/off for capabilities

Review trigger: When top 10% of users consistently request specific automation.

---

### NG-7: Social Media Management
**We will NOT manage social media.**

Rationale:
- Different use case entirely
- Specialized tools do it better
- Not daily priority for solo entrepreneurs
- Content creation is not our strength

Examples of excluded features:
- Post scheduling
- Social analytics
- Audience management
- Content calendars

Review trigger: Never - out of scope.

---

### NG-8: Project Management Tool
**We will NOT replace project management tools.**

Rationale:
- Linear/Notion/Asana already exist
- We integrate, not replace
- Sprint planning is not voice-first
- Team-oriented feature set

What we DO instead:
- Surface tasks from existing tools
- Create tasks in existing tools
- Track personal priorities

Review trigger: If integration limitations force task storage.

---

### NG-9: Note-Taking App
**We will NOT be a note-taking application.**

Rationale:
- Notion/Obsidian/Apple Notes exist
- Notes are passive, we're active
- Different mental model
- Feature creep risk

What we DO instead:
- Capture quick thoughts → route to action
- Meeting notes → extract tasks
- Voice memos → process into items

Review trigger: Never - core philosophy difference.

---

## User Non-Goals

### NG-10: Enterprise Users
**We will NOT optimize for enterprise users.**

Rationale:
- Different buying process
- Different compliance requirements
- Different feature expectations
- Different support model

Review trigger: When bootstrap phase complete and enterprise opportunity clear.

---

### NG-11: Free Users
**We will NOT have a free tier.**

Rationale:
- Attracts wrong users
- AI costs make free unsustainable
- Support burden from non-payers
- Devalues premium positioning

What we DO instead:
- Free trial (14 days)
- Money-back guarantee

Review trigger: If conversion from trial <10%.

---

## Quality Non-Goals

### NG-12: Feature Quantity
**We will NOT optimize for feature count.**

Rationale:
- Quality over quantity
- Each feature must be excellent
- Maintenance burden grows
- Complexity kills usability

Principle: Better to have 5 great features than 20 mediocre ones.

---

### NG-13: Speed to Market
**We will NOT ship incomplete features.**

Rationale:
- Trust is our product
- One bad experience kills adoption
- Better late and reliable
- Early users are evangelists

Exception: Clearly labeled beta features with opt-in.

---

## Enforcement

These non-goals are enforced by:

1. **Feature Request Review** - All requests checked against non-goals
2. **Roadmap Planning** - Non-goals reviewed quarterly
3. **Design Reviews** - Non-goal violations flagged
4. **This Document** - Authoritative reference

Changes to this document require:
- Clear business case
- Review trigger met
- Leadership approval
- User research support
