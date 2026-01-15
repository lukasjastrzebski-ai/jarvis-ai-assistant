# ADR-003: Local-First Data Architecture

**Status:** Accepted
**Date:** 2026-01-15

## Context
We need to decide where user data primarily lives - cloud or device.

## Decision
Local-first architecture with cloud sync.

## Rationale
1. Privacy: user data on their devices
2. Performance: instant access, no latency
3. Offline: full functionality without network
4. Trust: users control their data

## Consequences
- Complex sync implementation
- Conflict resolution needed
- Storage management on device
- Better privacy and performance
