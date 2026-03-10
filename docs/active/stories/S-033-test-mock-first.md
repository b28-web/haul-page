---
id: S-033
title: test-mock-first
status: open
epics: [E-015]
---

## Mock-First Test Refactor

The test suite runs ~120s wall-clock (117s sync, 5s async). 975 tests, but only 48 files run async — all the lightweight unit tests. Every DB-touching file (57 files) runs serially. Per-test tenant provisioning costs 150–200ms and happens in 33 files.

Deeper problem: many tests use `DataCase` or `ConnCase` with real DB when the logic under test is pure. Touching the DB for deterministic input→output functions is a code smell — it couples tests to infrastructure, blocks async execution, and inflates setup cost.

This story pushes tests down to the lowest viable tier by introducing mocks/stubs where DB access isn't the thing being tested.

### Diagnosis (from profiling)

| Category | Time | Tests | Key issue |
|----------|------|-------|-----------|
| LiveView (non-QA) | 41.5s | 249 | Every test provisions a tenant |
| QA/Browser (LiveView) | 22.4s | 110 | Duplicate coverage of non-QA LiveView tests |
| Domain/Unit | 21.3s | 495 | 21 DataCase files are sync unnecessarily |
| Controllers | 5.5s | 58 | Tenant provisioning per test |

### What this story addresses

1. **Pure-logic tests hiding behind DataCase** — EditApplier, Provisioner, worker modules test deterministic logic through full DB round-trips
2. **QA tests duplicating LiveView tests** — 7 `*_qa_test.exs` files (110 tests, 22s) test the same tier as their non-QA counterparts
3. **LiveView tests that test rendering, not DB** — preview_edit, chat flows can mock the data layer
4. **Async opportunity blocked by per-test DDL** — tenant provisioning prevents sandbox-based async

### What this story does NOT address (already done or not feasible)

- Tenant isolation tests — must create real schemas (security backbone)
- Content resource CRUD tests — Ash constraint validation genuinely needs DB
- Shared test tenant infrastructure — already exists in `test/support/shared_tenant.ex`

## Tickets

- T-033-01: audit-mock-candidates — catalog every DataCase/ConnCase test, classify as "needs DB" vs "mock-feasible", produce a migration plan
- T-033-02: extract-pure-logic — pull testable logic out of DB-coupled modules (EditApplier, Provisioner, workers) into pure functions with unit tests
- T-033-03: mock-service-layer — create `Haul.MockRepo` or per-module mocks (Mox) so tests can stub Ash reads/writes without DB
- T-033-04: dedup-qa-tests — merge or remove QA tests that duplicate non-QA LiveView coverage at the same tier
- T-033-05: async-unlock — flip DataCase files to `async: true` where shared-tenant + mocks have removed the DDL barrier

## Acceptance criteria

- No regression — `mix test` still passes, same or higher coverage
- At least 15 test files converted from DataCase/ConnCase to ExUnit.Case (pure unit)
- QA test count reduced by ≥50% (from 110 to ≤55) with no coverage loss
- `mix test` wall-clock time ≤60s (from ~120s)
- `mix haul.test_pyramid` shows improved unit:integration ratio
- Each converted test file has a comment explaining why it doesn't need DB
