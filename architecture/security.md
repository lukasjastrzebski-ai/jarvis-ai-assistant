# Security Architecture

**Stage:** 4
**Status:** Complete
**Date:** 2026-01-15

---

## Security Principles

1. **Least Privilege** - Minimal permissions requested and used
2. **Defense in Depth** - Multiple security layers
3. **Encryption Everywhere** - At rest and in transit
4. **Audit Trail** - All actions logged
5. **User Control** - Granular permission management

---

## Authentication

### User Authentication
- Email + password with strong requirements
- Optional: Sign in with Apple
- MFA via authenticator app (optional but encouraged)
- JWT tokens with 15-minute expiry, refresh rotation

### API Authentication
- Bearer tokens for API access
- Rate limiting per user/endpoint
- IP-based anomaly detection

---

## Authorization

### Permission Tiers
| Tier | Actions | Confirmation Required |
|------|---------|----------------------|
| Read | View emails, calendar | Never |
| Draft | Create drafts | Never |
| Send | Send emails/messages | Always (Assist), Configurable (Operator) |
| Delete | Remove items | Always |
| Financial | Invoices, payments | Always with 2FA |

### Operating Mode Permissions
- **Assist:** All actions require approval
- **Operator:** Low-risk actions auto-approved
- **Autopilot:** Configured workflows auto-execute

---

## Data Protection

### Encryption
- **Transit:** TLS 1.3 for all connections
- **At Rest:** AES-256 for database
- **Client:** iOS/macOS Keychain for credentials
- **Backups:** Encrypted before storage

### Data Isolation
- User data isolated by user_id
- Multi-tenant database with row-level security
- No cross-user data access possible

### Data Retention
- Active data: Indefinite
- Deleted items: 30-day soft delete
- Logs: 90-day retention
- User deletion: Full purge within 30 days

---

## Third-Party Security

### OAuth Integration Security
- Minimal scope requests
- Token refresh, not storage
- Immediate revocation on disconnect
- No credential storage

### AI Provider Security
- No PII in prompts where avoidable
- Data processing agreements in place
- No training on user data

---

## Incident Response

### Detection
- Automated anomaly detection
- User-reported security concerns
- Third-party security audits

### Response
- Immediate account lockout for suspicious activity
- User notification within 24 hours
- Full incident report within 72 hours
