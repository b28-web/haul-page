---
id: S-035
title: test-infrastructure
status: open
epics: [E-014, E-015]
---

## Test Infrastructure

S-033 fixes test *architecture* (what tier, mocking, dedup). S-034 fixes test *workflow* (how agents invoke tests). This story fixes test *infrastructure* — the underlying mechanisms that are slow even when architecture and workflow are optimal.

### Diagnosis

| Bottleneck | Per-test cost | Who pays | Avoidable? |
|------------|--------------|----------|------------|
| `CREATE SCHEMA` + tenant migrations | ~250ms | Tests needing isolated tenants (security, isolation, superadmin) | Reducible to ~50ms via template cloning |
| Global ETS (rate limiter) | forces `async: false` | Any file using `clear_rate_limits/0` | Yes — make ETS keys process-local |
| ChatSandbox global state | forces `async: false` | Chat/AI test files | Yes — caller-key pattern (like Mox) |
| LiveView mount for logic tests | ~30-50ms | Tests asserting on assigns, not HTML | Yes — test handle_event returns directly |
| No shared tenant pool | N/A | T-033-05 concurrency groups need it | Needs infrastructure |

### What this story addresses

1. **Fast schema cloning** — PL/pgSQL function to clone a pre-migrated template schema instead of running migrations from scratch. For tests that genuinely need per-test tenant isolation.
2. **Process-local test state** — make rate limiter ETS and ChatSandbox safe for concurrent test execution. Unblocks `async: true` for files currently forced sync by global state.
3. **Shared tenant pool** — provision N tenants at suite start, assign to ExUnit concurrency groups. Infrastructure that T-033-05 depends on.
4. **LiveView event unit testing** — helpers to call `handle_event`/`handle_info` directly and assert on socket assigns without full LiveView mount.

### What this story does NOT address

- Which tests to convert (S-033 audit)
- How agents invoke tests (S-034)
- QA deduplication (S-033 T-033-04)

## Tickets

- T-035-01: schema-template-clone — PL/pgSQL clone function for pre-migrated tenant schemas
- T-035-02: process-local-test-state — make rate limiter + ChatSandbox safe for async tests
- T-035-03: shared-tenant-pool — provision and manage N tenants for concurrency groups
- T-035-04: liveview-event-helpers — test handle_event/handle_info as pure functions

## Acceptance criteria

- Schema clone costs ≤50ms (down from ~250ms) — measure with `mix test --trace`
- At least 5 test files unblocked for `async: true` by process-local state changes
- Shared tenant pool provisions at suite start, assigns tenants to concurrency groups
- LiveView event helper tested and documented in `docs/knowledge/test-architecture.md`
- Full suite still passes — no regressions
