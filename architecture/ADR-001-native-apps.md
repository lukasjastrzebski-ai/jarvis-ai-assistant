# ADR-001: Native iOS/macOS Apps (No Web)

**Status:** Accepted
**Date:** 2026-01-15

## Context
We need to choose between native apps, cross-platform frameworks, or web-based approach.

## Decision
Build native SwiftUI apps for iOS and macOS. No web app.

## Rationale
1. Voice integration requires native Speech framework
2. Deep Apple ecosystem integration (Calendar, Mail, Contacts)
3. Performance and UX quality
4. Our target users are Apple-only
5. 80%+ code sharing possible with SwiftUI multi-platform

## Consequences
- No Android/Windows support
- Higher initial development investment
- Better quality and performance
- Deeper integration capabilities
