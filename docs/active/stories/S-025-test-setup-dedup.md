---
id: S-025
title: test-setup-dedup
status: open
epics: [E-014, E-013]
---

## Test Setup Deduplication

Reduce test suite wall time from ~90s to under 45s by eliminating redundant per-test tenant provisioning. The T-024-02 analysis identified this as "Tier 1" — the highest-impact fix that wasn't applied in S-024 due to test isolation concerns.

## Scope

- Move `create_authenticated_context()` from per-test `setup` to `setup_all` in the 14 heaviest files (estimated savings: 35-40s)
- Create a shared test tenant fixture that provisions once and is reused across multiple test files
- Verify all 845+ tests still pass with zero flakiness across multiple seeds
- Run timing telemetry to confirm the target is met
