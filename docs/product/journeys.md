# User Journeys

**Stage:** 2
**Status:** Complete
**Date:** 2026-01-15

---

## Journey 1: Morning Startup

### Scenario
Alex wakes up and wants to know what matters today.

### Steps

```
1. TRIGGER
   Alex: "Jarvis, what matters today?"

2. JARVIS RESPONSE
   Jarvis: "Three outcomes today: close Acme renewal, ship v1.3,
   unblock hiring. You have two meetings.

   I suggest deep work 9-11 on v1.3. The Acme proposal
   should go out at 11:15 before your noon call.

   Want me to draft the Acme email now?"

3. ALEX DECISION
   Alex: "Yes, draft it"

4. JARVIS ACTION
   - Drafts email based on context
   - Shows preview on screen
   - Waits for approval

5. RESOLUTION
   Alex: "Looks good, send it"
   Jarvis: "Sent. Your day plan is locked in. First deep work
   block starts in 45 minutes."
```

### Key Moments
- Quick summary, not information dump
- Proactive suggestions, not just status
- Clear next action
- Immediate value (draft ready)

---

## Journey 2: Email Triage

### Scenario
Alex has 23 unread emails and 15 minutes before a meeting.

### Steps

```
1. TRIGGER
   Alex opens Unified Inbox on Mac

2. JARVIS PRESENTATION
   - 23 items grouped by urgency
   - Top 3 flagged as "needs response today"
   - 8 marked as "can batch later"
   - 12 marked as "archive or quick action"

3. BATCH PROCESSING
   Alex: "Archive all newsletters"
   Jarvis: Archives 6 items

   Alex: "Reply to Sarah, confirm the meeting"
   Jarvis: Shows draft, Alex approves

   Alex: "Snooze the rest until tomorrow 9am"
   Jarvis: "Done. 3 items need attention today.
   Want me to schedule time for them?"

4. RESOLUTION
   Alex: "Yes, find 30 minutes this afternoon"
   Jarvis: "Blocked 3-3:30pm for email follow-ups"
```

### Key Moments
- Grouped by urgency, not chronology
- Batch actions reduce clicks
- Proactive scheduling suggestion
- Zero inbox achieved

---

## Journey 3: Meeting Preparation

### Scenario
Alex has a call with Acme Corp in 10 minutes.

### Steps

```
1. TRIGGER
   Jarvis notification: "Acme call in 10 minutes"

2. JARVIS BRIEF
   "Goal: Agree on scope and timeline.

   Context:
   - Last call 2 weeks ago, they objected to pricing
   - Open thread about implementation timeline
   - Sarah is the decision maker, Tom is technical lead

   Suggested talking points:
   1. Address pricing concern with annual discount
   2. Propose phased implementation

   Documents ready:
   - Proposal v2 (modified pricing)
   - Implementation timeline"

3. ALEX REVIEW
   Alex reviews on iPhone while walking to desk

4. RESOLUTION
   Alex: "Thanks, pull up the proposal"
   Jarvis: Opens proposal on Mac
```

### Key Moments
- Just-in-time context
- Actionable suggestions, not just history
- Linked to relevant documents
- Mobile-friendly brief

---

## Journey 4: Post-Meeting Capture

### Scenario
Alex just finished the Acme call.

### Steps

```
1. TRIGGER
   Alex: "Jarvis, capture meeting notes"

2. JARVIS PROMPT
   "What were the outcomes?"

3. ALEX DICTATION
   "They agreed to annual pricing, want to start in
   February. Tom needs technical docs by Friday.
   Sarah will send signed contract next week."

4. JARVIS PROCESSING
   - Creates structured notes
   - Extracts action items:
     * Send technical docs to Tom by Friday
     * Follow up with Sarah on contract next Wednesday
   - Updates CRM (if connected)
   - Adds to "waiting on" list

5. CONFIRMATION
   Jarvis: "Got it. I've created two follow-up tasks and
   added 'contract from Sarah' to waiting-on.
   Want me to draft the technical docs email now?"

6. RESOLUTION
   Alex: "Draft it for Friday morning"
   Jarvis: "Scheduled draft for Friday 9am"
```

### Key Moments
- Voice capture is fast
- Automatic task extraction
- CRM sync reduces duplicate work
- Proactive next step

---

## Journey 5: End of Day Shutdown

### Scenario
Alex is wrapping up at 5:30pm.

### Steps

```
1. TRIGGER
   Jarvis: "Ready for end of day review?"

2. JARVIS SUMMARY
   "Today:
   ✓ Shipped v1.3
   ✓ Sent Acme proposal
   ✗ Hiring post not published (moved to tomorrow)

   Open loops that will age poorly:
   1. Invoice to Client B (5 days overdue)
   2. Reply to investor email (2 days)
   3. Confirm Friday dinner

   Want me to handle any of these now?"

3. ALEX DECISIONS
   Alex: "Send the invoice now, draft investor reply
   for tomorrow, and yes confirm dinner"

4. JARVIS ACTIONS
   - Sends invoice
   - Creates draft for tomorrow
   - Sends dinner confirmation

5. RESOLUTION
   Jarvis: "Done. Tomorrow's top 3:
   1. Publish hiring post
   2. Review investor email
   3. Prep for Friday client call

   Anything else before shutdown?"

   Alex: "No, thanks"

   Jarvis: "Good night. Do Not Disturb enabled."
```

### Key Moments
- Proactive nudge, not user-initiated
- Clear accomplishments
- Specific open loops, not vague list
- Tomorrow prep included
- DND integration

---

## Journey 6: Focus Protection

### Scenario
Alex is in deep work mode, but interruptions keep coming.

### Steps

```
1. SETUP
   Alex: "Jarvis, I need 2 hours of deep work on the product spec"

2. JARVIS RESPONSE
   "Got it. Blocking 9-11am. I'll hold all notifications
   except emergencies.

   Definition of emergency:
   - Messages from Sarah (Acme deal)
   - Anything with 'urgent' from your investor list

   Sound right?"

3. ALEX CONFIRMS
   "Yes"

4. DURING FOCUS
   - 3 emails arrive → Jarvis queues them
   - Slack message from team → Jarvis queues
   - Email from Sarah about Acme → Jarvis: "Sarah from
     Acme emailed about contract timing. Interrupt or queue?"

5. RESOLUTION
   At 11am:
   Jarvis: "Focus block complete. You have 4 queued items.
   The Sarah email might need quick response."
```

### Key Moments
- Clear boundaries set
- Customizable emergency rules
- Interrupt option for true urgency
- Batch delivery after focus

---

## Journey Success Criteria

| Journey | Success Metric |
|---------|---------------|
| Morning Startup | <2 min to clear plan |
| Email Triage | Zero inbox in <15 min |
| Meeting Prep | Brief reviewed before call |
| Post-Meeting | Notes captured in <3 min |
| End of Day | Open loops cleared |
| Focus Protection | Uninterrupted block completed |
