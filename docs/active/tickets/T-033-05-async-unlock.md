---
id: T-033-05
story: S-033
title: async-unlock
type: task
status: open
priority: medium
phase: done
depends_on: [T-033-02, T-033-03, T-033-04]
---

## Context

After T-033-02 (extract pure logic), T-033-03 (mock service layer), and T-033-04 (dedup QA), many test files will no longer need DB access or will have drastically reduced DB setup. This ticket flips those files to `async: true` and uses **ExUnit concurrency groups** (available since Elixir 1.18, we're on 1.19.5) to parallelize tests that share tenant state.

Currently: 57 files `async: false`, 48 files `async: true`. The async files account for only 4.7s of the 121s wall clock. The sync files account for 116.7s — all sequential.

### ExUnit concurrency groups

Tests within a group run serially, but different groups run in parallel. This is the key mechanism for tests that need serial execution within a shared tenant but can parallelize across tenants. Create 2-3 shared tenants, assign test files to groups by tenant, and run groups concurrently — no mocking needed for these files.

## Acceptance Criteria

- Flip every newly-eligible test file to `async: true`
- For files that still need serial execution within a tenant (DB-touching ConnCase/DataCase), use ExUnit concurrency groups:
  - Create 2-3 shared test tenants in `test_helper.exs`
  - Assign test files to groups by tenant (e.g., `@moduletag :group_tenant_a`)
  - Groups run in parallel with each other, serial within
- Target: at least 15 additional files moved to async or into parallel groups
- Run `mix test` 3 times with different seeds to verify no flaky failures
- Files that use shared ETS (`clear_rate_limits`), global process state, or `ChatSandbox` must remain sync unless the shared state is made process-local
- Document any files that were attempted async but had to stay sync (and why)
- Wall-clock time for `mix test` ≤60s (target: 45s)
- Produce timing comparison: before vs. after in `docs/active/work/T-033-05/`

## Implementation Notes

- The main blocker for async was per-test `CREATE SCHEMA` (DDL can't be sandboxed). Files converted to mocks in T-033-03 no longer have this blocker
- Files that still use `DataCase` with the shared test tenant can potentially go async since they share a pre-existing schema and use Ecto Sandbox for row-level isolation
- **Concurrency groups** (ExUnit 1.18+): `use ExUnit.Case, async: {:group, :tenant_a}` — tests in `:tenant_a` run serially, but `:tenant_a` and `:tenant_b` groups run in parallel. This halves wall-clock time for DB-touching tests without any mocking
- `ChatSandbox` uses process dictionary — verify it's safe for concurrent access or add a caller-key pattern (like Mox)
- `clear_rate_limits/0` wipes the ETS table globally — files using this cannot be async unless rate limiting is made per-process or the ETS key includes the test PID
- After flipping, run `mix test --seed 0` to force a deterministic order and catch ordering-dependent failures
- Run `mix test` with `--max-cases` set to core count to verify parallel execution actually helps

## Risk

- Async tests that share global state will produce intermittent failures. If any test fails on the 2nd or 3rd run but not the 1st, it's a shared-state problem — revert that file to sync and document the blocker
