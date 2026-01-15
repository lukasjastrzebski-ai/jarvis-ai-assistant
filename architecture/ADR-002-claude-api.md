# ADR-002: Claude API as Primary AI Provider

**Status:** Accepted
**Date:** 2026-01-15

## Context
We need an AI provider for natural language understanding, drafting, and reasoning.

## Decision
Use Anthropic Claude API as primary, OpenAI as fallback.

## Rationale
1. Superior instruction following
2. Better tool use capabilities
3. Longer context window (200K)
4. More reliable for professional writing
5. Anthropic safety alignment

## Consequences
- API costs per request
- Dependency on external service
- Need fallback strategy for outages
- Must handle rate limits gracefully
