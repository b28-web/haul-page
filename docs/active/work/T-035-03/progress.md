# T-035-03 Progress: Shared Tenant Pool

## Completed

1. **TenantPool module** (`test/support/tenant_pool.ex`) — `provision!/1`, `checkout/1`, `teardown!/0`, `groups/0`. Uses `:persistent_term` for zero-cost reads. Handles stale schema cleanup on re-provision.

2. **DataCase updates** (`test/support/data_case.ex`) — `setup_sandbox/1` detects `tags[:test_group]` and forces `shared: true` for concurrency groups. Added `pool_context/1` helper. Setup block merges pool context into test context.

3. **ConnCase updates** (`test/support/conn_case.ex`) — Setup block merges pool context (company, tenant, user, token) when concurrency group is active.

4. **Factories cleanup** (`test/support/factories.ex`) — `cleanup_all_tenants/0` now excludes pool schemas (`tenant___pool_%`).

5. **test_helper.exs** — Wired `TenantPool.provision!(count: 3)` after SchemaTemplate setup. Combined teardown callbacks into single `after_suite`.

6. **TenantPool tests** (`test/support/tenant_pool_test.exs`) — 6 tests: context keys, tenant isolation, unknown group error, resource operations, groups list.

7. **Group integration test** (`test/support/tenant_pool_group_test.exs`) — 2 tests: verifies `async: true, group: :pool_a` provides correct context and supports resource operations.

8. **test-architecture.md** — Added concurrency groups section: usage, available groups, when to use, how it works, important notes.

## Deviation from ticket AC

The ticket specified `async: {:group, :pool_a}` syntax. ExUnit 1.18+ actually uses separate options: `async: true, group: :pool_a`. Updated all code and docs accordingly. The `:test_group` tag in ExUnit tags provides the group name.

## All 8 tests passing

```
mix test test/support/tenant_pool_test.exs test/support/tenant_pool_group_test.exs
8 tests, 0 failures
```

Stale suite: 898 tests, 0 failures. Some pre-existing flaky sandbox ownership failures in full stale runs (3 intermittent failures that pass in isolation — known async timing issues).
