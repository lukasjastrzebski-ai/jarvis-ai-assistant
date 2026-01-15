# Product Definition

**Stage:** 2
**Status:** Complete
**Date:** 2026-01-15

---

## What Jarvis Is

Jarvis is a **voice-first AI operator** for solo entrepreneurs that:

1. **Runs your day** - Maintains live priorities, detects overload, enforces focus
2. **Handles communications** - Triage, draft, schedule, follow up
3. **Manages calendar** - Schedule intelligently, brief before meetings, capture outcomes
4. **Executes work** - Create documents, run workflows, track open loops
5. **Protects focus** - Smart interruptions, batched notifications, context switching detection

---

## Platform

### Primary Interface: iOS App
- Voice-first interaction
- Quick approvals and capture
- Notifications with action buttons
- Widget for daily plan

### Secondary Interface: macOS App
- Full visual interface
- Batch triage and planning
- Deep work mode controls
- Extended editing capabilities

### Sync
- Real-time sync between devices
- Unified state and memory
- Seamless handoff

---

## Operating Modes

### 1. Assist Mode (Default Start)
- Jarvis drafts and suggests
- User reviews and approves everything
- Training period for Jarvis to learn preferences

### 2. Operator Mode (After Trust Built)
- Jarvis executes within guardrails
- Automatic: scheduling, filing, drafting, task creation
- User gets digest of actions taken

### 3. Autopilot Mode (Selective, Advanced)
- Low-risk recurring workflows run automatically
- Daily startup, end-of-day shutdown, follow-ups
- User gets daily summary

---

## Core Capabilities

### 1. Unified Inbox
Everything becomes an "item" with status:
- **Incoming:** Email, DM, missed call, calendar invite, notification
- **Created:** Voice notes, quick thoughts, ideas
- **Generated:** Drafts, summaries, suggested tasks

Each item has:
- Action buttons (Reply, Delegate, Schedule, Add task, Snooze, Archive)
- Jarvis suggestion panel
- One-sentence goal field

### 2. Voice Interaction
Natural language commands:
- "Jarvis, plan my day around these 3 priorities..."
- "Reply to Anna politely, propose Tue 10 or Wed 2, keep it short"
- "Remind me when I arrive home to order filters"
- "I have 25 minutes. Give me the highest leverage task"

Response pattern:
- Summary first, details on request
- Single best next action, not menus
- Confirmation only when risk is high

### 3. Memory System
Operational memory, not trivia:
- **People:** Roles, preferences, last interaction, open loops
- **Projects:** Goals, constraints, decisions, status
- **Writing style:** Tone profiles per context
- **Rules:** "Never schedule before 10", "No Fridays", "Protect 9-12"
- **Definitions:** Terminology, pricing, customer segments

Memory is editable, inspectable, segmentable (personal vs. work).

### 4. Activity Log
Complete audit trail:
- Every action Jarvis took
- Why it took that action
- Undo capability where possible
- Approval/rejection history

---

## Integrations (MVP)

### Core
- Apple Calendar
- Apple Mail
- Apple Reminders
- Apple Contacts

### Extended
- Gmail / Google Calendar
- Slack (if feasible)
- Notion / Google Docs

### Future
- Stripe / PayPal (read-first)
- CRM (HubSpot/Pipedrive)
- Zoom / Meet

---

## Scope Boundaries

| In Scope | Out of Scope |
|----------|--------------|
| iPhone + Mac | Android, Windows, Web |
| Solo entrepreneurs | Teams, enterprises |
| Productivity operations | Content creation |
| Email/calendar/tasks | Social media management |
| English | Multi-language (future) |
| Voice + visual | Voice-only or visual-only |
