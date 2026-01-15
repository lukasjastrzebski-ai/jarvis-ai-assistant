# F-002 Voice Interaction - Test Plan

## Unit Tests

| Test ID | Description | Input | Expected |
|---------|-------------|-------|----------|
| VI-001 | Wake word detection | "Jarvis" audio | Activation triggered |
| VI-002 | Simple command parse | "What's next" | Intent: next_item |
| VI-003 | Email command parse | "Reply to John" | Intent: email_reply, recipient: John |

## Integration Tests

| Test ID | Description | Setup | Expected |
|---------|-------------|-------|----------|
| VI-101 | Voice to action | "Archive this" | Item archived |
| VI-102 | Voice to draft | "Draft reply..." | Draft generated |
| VI-103 | Confirmation flow | High-risk command | Confirmation prompt shown |

## E2E Tests

| Test ID | Scenario | Steps | Expected |
|---------|----------|-------|----------|
| VI-201 | Voice email workflow | Say "Reply to Sarah, confirm meeting" | Draft shown, approved, sent |
| VI-202 | Voice planning | "What matters today?" | Plan presented verbally |

## Performance Tests

| Test ID | Metric | Threshold |
|---------|--------|-----------|
| VI-301 | Recognition latency | <1 second |
| VI-302 | Response start | <2 seconds |
| VI-303 | Accuracy (test corpus) | >90% |
