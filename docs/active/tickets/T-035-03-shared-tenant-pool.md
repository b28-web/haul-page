---
id: T-035-03
story: S-035
title: shared-tenant-pool
type: task
status: open
priority: medium
phase: done
depends_on: [T-035-01]
---

## Context

T-033-05 (async-unlock) plans to use ExUnit concurrency groups to parallelize DB-touching tests. Tests within a group run serially; groups run in parallel. Each group needs its own tenant schema so there's no cross-group data interference.

This ticket builds the infrastructure: provision N tenant schemas at suite start, expose them to test files via a pool mechanism, and integrate with ExUnit's concurrency group configuration.

## Acceptance Criteria

- Provision N shared tenants (start with 3) in `test_helper.exs` at suite start
- Each tenant is fully migrated and seeded (if needed)
- Expose `Haul.Test.TenantPool.checkout(group)` that returns a tenant context for a given concurrency group
- Test files opt in via:
  ```elixir
  use HaulWeb.ConnCase, async: {:group, :tenant_a}
  ```
  and receive the corresponding tenant's context in their setup
- ConnCase/DataCase updated to support the `async: {:group, _}` option
- Pool cleans up tenant schemas on suite exit via `on_exit` in test_helper
- Document concurrency group assignment in `docs/knowledge/test-architecture.md`

## Implementation Notes

- Tenant provisioning at suite start:
  ```elixir
  # test_helper.exs
  tenants = Haul.Test.TenantPool.provision!(count: 3)
  # Creates schemas: __pool_a__, __pool_b__, __pool_c__
  ```
- If T-035-01 (schema template clone) is done, use `clone_tenant/1` for fast provisioning (~50ms each). Otherwise use `build_authenticated_context/0` (~250ms each). Either way, it's a one-time cost at suite start.
- ExUnit concurrency groups (1.18+):
  ```elixir
  # In the test file
  use ExUnit.Case, async: {:group, :tenant_a}
  ```
  All files tagged `:tenant_a` run serially with each other but in parallel with `:tenant_b` files.
- Assignment strategy: distribute test files across groups to balance wall-clock time. Use `mix test --trace` timing data to inform assignment.
- The pool module should be simple — a map of `%{group_name => tenant_context}` stored in a persistent term or application env during the test run.

## Risks

- If tests within a group mutate shared tenant state (delete all services, change site config), later tests in the group may fail. Mitigation: tests should create their own records with unique identifiers, not rely on "the only record"
- Adding a 3rd tenant to the pool adds ~250ms (or ~50ms with clone) to suite startup. Acceptable.
- Concurrency group assignment needs periodic rebalancing as tests are added/removed
