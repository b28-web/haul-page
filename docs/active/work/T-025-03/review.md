# T-025-03 Review: Timing Verification

## Summary

Verified and fixed test suite performance after T-025-01 (setup_all migration) and
T-025-02 (shared test tenant). Eliminated seed-dependent flakiness by removing
redundant `on_exit` DDL cleanup from per-test setup blocks.

## Full Suite Result

```
845 tests, 0 failures (1 excluded)
Suite time: 28-33s (target: <45s)
10/10 seeds: 0 failures
```

## Before/After Comparison

| Metric | Before (T-024-02) | Current (T-025-03) |
|--------|-------------------|-------------------|
| Wall clock | 173s | 28-33s |
| Tests | 746 | 845 |
| Failures | 0 | 0 |
| Setup overhead | 22ms | ~300ms |
| Sync files | 55 (169s) | 58 (27-31s) |
| Async files | 30 (4.1s) | 37 (1-2s) |

**Improvement: 173s → 30s (83% reduction)**

### Top 10 Slowest Files

| # | File | Time | Tests |
|---|------|------|-------|
| 1 | preview_edit_test.exs | 4.0s | 13 |
| 2 | chat_qa_test.exs | 3.9s | 25 |
| 3 | provision_qa_test.exs | 3.2s | 14 |
| 4 | chat_live_test.exs | 2.7s | 22 |
| 5 | superadmin_qa_test.exs | 1.2s | 18 |
| 6 | impersonation_test.exs | 0.9s | 16 |
| 7 | onboarding_live_test.exs | 0.7s | 14 |
| 8 | timing_formatter_test.exs | 0.6s | 4 |
| 9 | security_test.exs (admin) | 0.6s | 11 |
| 10 | proxy_qa_test.exs | 0.6s | 13 |

## Stability Results

### 10 Seeds — All Pass

| Seed | Tests | Failures | Time |
|------|-------|----------|------|
| 11111 | 845 | 0 | 33.4s |
| 22222 | 845 | 0 | ~30s |
| 33333 | 845 | 0 | ~30s |
| 44444 | 845 | 0 | ~30s |
| 55555 | 845 | 0 | ~30s |
| 99999 | 845 | 0 | 32.3s |
| 77777 | 845 | 0 | 32.1s |
| 12345 | 845 | 0 | 29.0s |
| 54321 | 845 | 0 | 28.0s |
| 88888 | 845 | 0 | 28.9s |

## Acceptance Criteria

| Criterion | Status |
|-----------|--------|
| Run HAUL_TEST_TIMING=1 and capture timing report | Done — 27.8s |
| Total wall time under 45 seconds | Met — 28-33s |
| No flaky tests across 5 consecutive runs | Met — 10/10 seeds pass |
| Full suite passes with 0 failures | Met |
| Before/after comparison documented | Done |

## Open Concerns

### 1. CostTracker OwnershipError (pre-existing, warning only)
`CostTracker.record_baml_call/1` writes to DB from async Task processes without
sandbox checkout. Produces warnings but doesn't cause test failures since the
on_exit DDL cleanup removal eliminated the cascading interference.

### 2. "If using shared mode" warnings (cosmetic)
Some seeds produce stderr warnings about shared mode. These are from the CostTracker
async writes and do not cause test failures. Could be suppressed by making
CostTracker no-op in test env.
