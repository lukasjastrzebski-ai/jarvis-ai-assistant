# Integrations Architecture

**Stage:** 4
**Status:** Complete
**Date:** 2026-01-15

---

## Integration Framework

```
┌─────────────────────────────────────────┐
│         Integration Manager              │
│  ┌─────────────────────────────────────┐│
│  │     Adapter Interface               ││
│  │  - connect()                        ││
│  │  - disconnect()                     ││
│  │  - sync()                           ││
│  │  - execute(action)                  ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
         │          │          │
    ┌────┴────┐ ┌───┴────┐ ┌───┴────┐
    │  Gmail  │ │ Google │ │ Apple  │
    │ Adapter │ │Calendar│ │  Mail  │
    └─────────┘ └────────┘ └────────┘
```

---

## MVP Integrations

### Gmail (F-003)
- **Auth:** OAuth 2.0
- **Scopes:** gmail.readonly, gmail.compose, gmail.send
- **Sync:** Push notifications via Pub/Sub, polling fallback
- **Rate Limits:** 250 quota units/user/second

### Apple Mail (F-003)
- **Auth:** System permissions
- **API:** Apple Mail framework (limited)
- **Fallback:** IMAP for send capability
- **Limitation:** Background access restricted

### Apple Calendar (F-004)
- **Auth:** EventKit permissions
- **API:** EventKit framework
- **Sync:** Native iOS sync
- **Features:** Full CRUD, reminders support

### Google Calendar (F-004)
- **Auth:** OAuth 2.0
- **Scopes:** calendar.readonly, calendar.events
- **Sync:** Push notifications, polling fallback
- **Rate Limits:** 100 requests/100 seconds

---

## Integration Patterns

### Sync Pattern
```
1. Initial Sync: Full fetch on connect
2. Incremental: Delta sync every 60 seconds
3. Real-time: Push notifications where available
4. Conflict: Server timestamp wins
```

### Error Handling
```
1. Transient: Retry with exponential backoff
2. Auth: Prompt user to re-authenticate
3. Rate Limit: Queue and delay
4. Permanent: Notify user, disable integration
```

---

## Future Integrations (Post-MVP)

| Integration | Priority | API Type |
|-------------|----------|----------|
| Slack | P1 | REST + WebSocket |
| Notion | P2 | REST |
| Linear | P2 | GraphQL |
| Stripe | P2 | REST |
| HubSpot | P3 | REST |
