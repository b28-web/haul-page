# T-035-03 Structure: Shared Tenant Pool

## New Files

### `test/support/tenant_pool.ex` — `Haul.Test.TenantPool`

Public API:
- `provision!(opts)` — creates N pool tenants at suite start
  - `opts`: `[count: 3]` (default 3)
  - Creates companies with slugs `__pool_a__`, `__pool_b__`, `__pool_c__`
  - Clones template schema for each via `SchemaTemplate.clone!/1`
  - Registers a user in each tenant
  - Stores `%{pool_a: context, pool_b: context, pool_c: context}` in `:persistent_term`
  - Returns the list of group names
- `checkout(group)` — returns `%{company, tenant, user, token}` for a group
  - Reads from `:persistent_term`
  - Raises if group not provisioned
- `teardown!()` — drops all pool schemas, deletes persistent_term key
- `groups()` — returns list of available group names

Internal:
- `@pool_key :haul_test_tenant_pool` — persistent_term key
- `@group_names [:pool_a, :pool_b, :pool_c]` — or derived from count
- Uses `Factories.build_company/1` + `SchemaTemplate.clone!/1` + `Factories.build_user/2`
- Wraps DDL in checkout/checkin of sandbox in :auto mode (same pattern as SchemaTemplate.setup!)

### `test/support/tenant_pool_test.exs` — Unit tests for TenantPool

- Test that `provision!` creates schemas and stores contexts
- Test that `checkout/1` returns correct context per group
- Test that `checkout/1` raises for unknown group
- Test that `teardown!` cleans up schemas

## Modified Files

### `test/test_helper.exs`

Add after SchemaTemplate setup:
```elixir
Haul.Test.TenantPool.provision!(count: 3)
ExUnit.after_suite(fn _ ->
  Haul.Test.TenantPool.teardown!()
  Haul.Test.SchemaTemplate.teardown!()
end)
```

Remove the separate `SchemaTemplate.teardown!` after_suite — combine into one callback.

### `test/support/data_case.ex`

Modify `setup_sandbox/1`:
```elixir
def setup_sandbox(tags) do
  shared = case tags[:async] do
    {:group, _} -> true
    true -> false
    _ -> true
  end
  pid = Sandbox.start_owner!(Haul.Repo, shared: shared)
  on_exit(fn -> Sandbox.stop_owner(pid) end)
end
```

Add `pool_context/1` helper:
```elixir
def pool_context(tags) do
  case tags[:async] do
    {:group, group} -> Haul.Test.TenantPool.checkout(group)
    _ -> nil
  end
end
```

### `test/support/conn_case.ex`

Update `setup` to inject pool context when using groups:
```elixir
setup tags do
  Haul.DataCase.setup_sandbox(tags)
  base = %{conn: Phoenix.ConnTest.build_conn()}
  case Haul.DataCase.pool_context(tags) do
    nil -> {:ok, base}
    ctx -> {:ok, Map.merge(base, ctx)}
  end
end
```

### `test/support/factories.ex`

Update `cleanup_all_tenants/0` to also exclude pool schemas:
```elixir
WHERE schema_name LIKE 'tenant_%'
  AND schema_name != 'tenant_shared-test-co'
  AND schema_name NOT LIKE 'tenant___pool_%'
```

### `docs/knowledge/test-architecture.md`

Add section on concurrency groups:
- How to opt in: `use HaulWeb.ConnCase, async: {:group, :pool_a}`
- What it provides (pre-provisioned tenant context in test context)
- When to use groups vs `async: true` vs `async: false`
- Available groups: `:pool_a`, `:pool_b`, `:pool_c`

## Module Boundaries

```
test_helper.exs
  └─ Haul.Test.TenantPool.provision!/1
       └─ Haul.Test.SchemaTemplate.clone!/1 (existing)
       └─ Haul.Test.Factories.build_company/1 (existing)
       └─ Haul.Test.Factories.build_user/2 (existing)

DataCase.setup_sandbox/1
  └─ detects {:group, _} → shared: true

DataCase.pool_context/1
  └─ Haul.Test.TenantPool.checkout/1

ConnCase setup
  └─ DataCase.setup_sandbox/1
  └─ DataCase.pool_context/1
```

## No Changes Needed

- `lib/` — no production code changes
- `ProvisionTenant` — skip flag already exists from T-035-01
- `SchemaTemplate` — used as-is
