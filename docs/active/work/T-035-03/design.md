# T-035-03 Design: Shared Tenant Pool

## Problem

Tests that create their own tenant per-test pay ~27ms (fast clone) or ~231ms (migration) each. Most tests don't need isolated tenants — they just need a pre-provisioned schema with tables. A pool of pre-created tenants assigned to concurrency groups would eliminate per-test provisioning overhead and enable group-level parallelism.

## Approach: Persistent Term Pool

### How it works

1. **Suite start** (`test_helper.exs`): Provision N tenant schemas using `SchemaTemplate.clone!`, store the mapping `%{group_name => tenant_string}` in `:persistent_term`.

2. **Pool module** (`Haul.Test.TenantPool`): Simple API:
   - `provision!(count: 3)` — creates `__pool_a__`, `__pool_b__`, `__pool_c__` schemas via clone, builds company + user for each, stores in persistent_term
   - `checkout(group)` — returns `%{company, tenant, user, token}` for the given group
   - `teardown!()` — drops pool schemas

3. **ConnCase/DataCase** — detect `async: {:group, _}` in tags, call `TenantPool.checkout(group)` to get tenant context, configure sandbox in shared mode for the group.

### Why persistent_term

- Read-only after suite start — no contention
- Process-safe — any test process can read it
- Zero-cost reads (copied to process heap)
- Application env works too, but persistent_term is the idiomatic choice for read-heavy, write-once data

### Alternatives considered

**ETS table**: Viable but overkill for a static map written once. Persistent_term is simpler.

**GenServer pool**: Adds process management complexity for no benefit — pool is static for the entire suite.

**Application env**: Works (already used for operator_context). But persistent_term is cleaner for test infrastructure that shouldn't leak into app config namespace.

**Decision**: persistent_term. Simple, fast, appropriate for write-once read-many pattern.

## Schema Naming

Pool schemas: `tenant___pool_a__`, `tenant___pool_b__`, `tenant___pool_c__`
- Double underscore prefix distinguishes pool schemas from test-created schemas
- Matches the `__test_template__` convention from SchemaTemplate
- Cleanup query: `WHERE schema_name LIKE 'tenant___pool_%'`

Company slugs: `__pool_a__`, `__pool_b__`, `__pool_c__`
- Unique, won't collide with real test companies

## Group Assignment

Start with 3 groups: `:pool_a`, `:pool_b`, `:pool_c`. Test files opt in:
```elixir
use Haul.DataCase, async: {:group, :pool_a}
# or
use HaulWeb.ConnCase, async: {:group, :pool_a}
```

This ticket builds the infrastructure only. Actual assignment of test files to groups is a follow-up concern (T-033-05 already has most files on async: true). The pool is available for files that want to opt in.

## Sandbox Configuration for Groups

Groups need `shared: true` sandbox mode — all tests in a group share a single DB connection. This is the same as `async: false` sandbox behavior.

The `setup_sandbox` function currently does:
```elixir
pid = Sandbox.start_owner!(Haul.Repo, shared: not tags[:async])
```

With groups, `tags[:async]` is `{:group, :pool_a}`, which is truthy. So `shared: not tags[:async]` would be `false` — **wrong** for groups that share a tenant.

Fix: Detect group tuples and force `shared: true`:
```elixir
def setup_sandbox(tags) do
  shared = case tags[:async] do
    {:group, _} -> true
    true -> false
    _ -> true  # async: false or nil
  end
  pid = Sandbox.start_owner!(Haul.Repo, shared: shared)
  on_exit(fn -> Sandbox.stop_owner(pid) end)
end
```

## ConnCase/DataCase Integration

Add a `setup` clause that detects group tags and provides the pool tenant context:

```elixir
setup tags do
  Haul.DataCase.setup_sandbox(tags)
  case tags[:async] do
    {:group, group} ->
      ctx = Haul.Test.TenantPool.checkout(group)
      {:ok, Map.put(ctx, :conn, Phoenix.ConnTest.build_conn())}
    _ ->
      {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

Tests using groups get `%{conn, company, tenant, user, token}` automatically in their context — no manual setup needed.

## Provisioning Order

In `test_helper.exs`:
1. Cleanup stale data (existing)
2. Ensure operator tenant (existing)
3. **Provision pool tenants** (new)
4. Start ExUnit (existing)
5. Setup SchemaTemplate (existing — still needed for per-test cloning)
6. **After suite: teardown pool** (new)

Pool provisioning must happen before `Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)` since it needs auto mode for DDL.

## Cleanup Strategy

- `ExUnit.after_suite` callback drops all pool schemas
- `cleanup_all_tenants` in test_helper.exs already excludes specific schemas — add pool schema exclusion
- Pool schemas persist for entire suite run (that's the point)
