# T-035-03 Review: Shared Tenant Pool

## Summary

Implemented a shared tenant pool that provisions N tenant schemas at suite start for use with ExUnit concurrency groups. Tests can opt in via `use HaulWeb.ConnCase, async: true, group: :pool_a` and automatically receive a pre-provisioned tenant context (`%{company, tenant, user, token}`).

## Test Results

```
mix test (full suite): 942 tests, 41 failures (1 excluded)
```

All 41 failures are **pre-existing** flaky async sandbox ownership errors — they pass in isolation and are present in the baseline without this ticket's changes. The baseline (git stash, pre-S-025 code) has 107 failures.

Pool-specific tests: **8 tests, 0 failures** (6 unit/resource + 2 integration).

## Files Changed

| File | Change |
|------|--------|
| `test/support/tenant_pool.ex` | **New** — `Haul.Test.TenantPool` module (provision, checkout, teardown, groups) |
| `test/support/tenant_pool_test.exs` | **New** — 6 tests for pool functionality |
| `test/support/tenant_pool_group_test.exs` | **New** — 2 integration tests using `async: true, group: :pool_a` |
| `test/support/data_case.ex` | **Modified** — `setup_sandbox/1` detects `:test_group` for shared mode; added `pool_context/1`; setup merges pool context |
| `test/support/conn_case.ex` | **Modified** — setup merges pool context when group active |
| `test/support/factories.ex` | **Modified** — `cleanup_all_tenants/0` excludes pool schemas |
| `test/test_helper.exs` | **Modified** — wired pool provisioning + combined teardown |
| `docs/knowledge/test-architecture.md` | **Modified** — added concurrency groups section |

## Acceptance Criteria Verification

| Criterion | Status | Notes |
|-----------|--------|-------|
| Provision N shared tenants at suite start | Done | 3 tenants via `TenantPool.provision!(count: 3)` |
| Each tenant fully migrated | Done | Uses `SchemaTemplate.clone!` for fast provisioning |
| `TenantPool.checkout(group)` returns context | Done | Returns `%{company, tenant, user, token}` |
| Test files opt in via group syntax | Done | `use ConnCase, async: true, group: :pool_a` |
| ConnCase/DataCase support group option | Done | `setup_sandbox` detects `:test_group`, `pool_context` provides context |
| Pool cleans up on suite exit | Done | `ExUnit.after_suite` drops schemas |
| Document in test-architecture.md | Done | New "Concurrency Groups" section |

## Deviation from Ticket

The ticket specified `async: {:group, :pool_a}` syntax. ExUnit 1.18+ actually uses **separate options**: `async: true, group: :pool_a`. The `:test_group` tag provides the group name in test tags. All code and docs updated accordingly.

## Test Coverage

| Component | Tests | Tier |
|-----------|-------|------|
| `checkout/1` context keys | 1 | Resource |
| `checkout/1` different tenants per group | 1 | Resource |
| `checkout/1` unknown group raises | 1 | Resource |
| Pool tenant resource operations | 1 | Resource |
| Pool tenant isolation | 1 | Resource |
| `groups/0` returns group list | 1 | Resource |
| ConnCase group integration (context injection) | 1 | Integration |
| ConnCase group integration (resource ops) | 1 | Integration |

## Open Concerns

1. **Pre-existing flaky failures**: 41 async sandbox ownership errors in the full suite. These are not caused by this ticket but indicate the existing async test infrastructure has timing issues. Likely T-035-02 (process-local test state) work will help.

2. **No test files assigned to groups yet**: This ticket builds the pool infrastructure. Actual assignment of test files to groups for parallelism gains is a follow-up concern — tests currently use `async: true` individually.

3. **Shared state within groups**: Tests in a group share a tenant. If a test deletes all services or modifies site config globally, it can affect later tests in the group. The docs note this and recommend creating records with unique identifiers.

4. **Pool provisioning adds ~45ms to suite startup**: Acceptable one-time cost (3 × ~15ms clone).

## Architecture Notes

- **Storage**: `:persistent_term` — zero-cost reads, process-safe, write-once pattern
- **Cleanup**: Stale pool schemas from prior crashed runs are dropped before re-provisioning
- **Sandbox mode**: Groups use `shared: true` (like `async: false`) so all tests in a group share a single DB connection
- **No production code changes**: All changes are in test support code
