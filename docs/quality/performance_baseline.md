# Performance Baseline

**Last Updated:** 2026-01-16
**Test Environment:** macOS 14.0, Apple Silicon

---

## Performance Benchmarks

### Core Operations

| Operation | Target | Measured | Status |
|-----------|--------|----------|--------|
| Single embedding generation | <100ms | 0.16ms | ✓ Pass |
| Batch embedding (20 texts) | <500ms | 2.89ms | ✓ Pass |
| Similarity search (100 candidates) | <50ms | 15.75ms | ✓ Pass |
| Calendar operations | <20ms | 0.24ms | ✓ Pass |
| Calendar event creation | <5ms | 0.01ms | ✓ Pass |
| Email fetch | <10ms | <1ms | ✓ Pass |
| Mark as read | <2ms | <1ms | ✓ Pass |

### Authentication & API

| Operation | Target | Measured | Status |
|-----------|--------|----------|--------|
| Authentication | <200ms | 103ms | ✓ Pass |
| Token validation | <5ms | <1ms | ✓ Pass |
| Item sync (50 items) | <300ms | 209ms | ✓ Pass |
| Health check | <10ms | <1ms | ✓ Pass |

### Concurrency & Stress

| Test | Target | Measured | Status |
|------|--------|----------|--------|
| Concurrent requests (50 sessions) | <sequential | 102ms | ✓ Pass |
| Mixed workload | <1000ms | 519ms | ✓ Pass |
| High volume (500 ops) | 0 errors | 0 errors | ✓ Pass |
| Throughput | >1000 ops/sec | 17,445 ops/sec | ✓ Pass |

### Memory Efficiency

| Metric | Value |
|--------|-------|
| 1000 embeddings generation | 0.12s |
| Memory per 1000 embeddings | ~5MB |
| Embedding dimension | 1536 |

---

## Baseline Values (Raw)

```
api_health_ms: 0.003
calendar_fetch_ms: 0.205
email_fetch_ms: 0.001
embedding_single_ms: 0.155
```

---

## Test Summary

- **Total Tests:** 316
- **Performance Tests:** 15
- **E2E Tests:** 20
- **Mock Services Tests:** 41
- **Unit Tests:** 240

---

## Recommendations

1. **Current Status:** All benchmarks well within targets
2. **Optimization Priority:** Low (system performs efficiently)
3. **Monitoring:** Continue tracking in CI/CD pipeline

---

## Notes

- Benchmarks measured with mock services (no external API latency)
- Real-world performance may vary with network conditions
- Recommend re-baseline after connecting to production services
