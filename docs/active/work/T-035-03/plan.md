# T-035-03 Plan: Shared Tenant Pool

## Step 1: Create TenantPool module

**File**: `test/support/tenant_pool.ex`

Create `Haul.Test.TenantPool` with:
- `provision!(count: 3)` — checkout sandbox in auto mode, create companies with `build_company`, clone schemas with `SchemaTemplate.clone!`, register users with `build_user`, store in persistent_term, restore sandbox mode
- `checkout(group)` — read from persistent_term, raise if not found
- `teardown!()` — drop pool schemas, delete persistent_term
- `groups()` — return available group names

**Verify**: Module compiles (`mix compile --warnings-as-errors`)

## Step 2: Update DataCase sandbox handling

**File**: `test/support/data_case.ex`

- Modify `setup_sandbox/1` to detect `{:group, _}` tuples and set `shared: true`
- Add `pool_context/1` helper that returns tenant context for group tags, nil otherwise

**Verify**: `mix test --stale`

## Step 3: Update ConnCase setup

**File**: `test/support/conn_case.ex`

- Update `setup` block to call `DataCase.pool_context(tags)` and merge into test context when present

**Verify**: `mix test --stale`

## Step 4: Update factories cleanup

**File**: `test/support/factories.ex`

- Add `AND schema_name NOT LIKE 'tenant___pool_%'` exclusion to `cleanup_all_tenants/0`

**Verify**: `mix test --stale`

## Step 5: Wire into test_helper.exs

**File**: `test/test_helper.exs`

- Add `Haul.Test.TenantPool.provision!(count: 3)` after SchemaTemplate setup
- Combine teardown callbacks into a single `ExUnit.after_suite`

**Verify**: `mix test --stale` (this triggers full pool provisioning)

## Step 6: Write TenantPool tests

**File**: `test/support/tenant_pool_test.exs`

Tests:
- `provision!` creates expected schemas in the database
- `checkout/1` returns valid context with company, tenant, user, token
- `checkout/1` for each group returns different tenants
- `checkout/1` raises for unknown group name
- After `teardown!`, schemas are dropped

Use `ExUnit.Case` (tier 1/2 — needs DB for schema verification).

**Verify**: `mix test test/support/tenant_pool_test.exs`

## Step 7: Write a smoke test with concurrency group

Create a small test that uses `async: {:group, :pool_a}` to verify the full integration:
- Gets tenant context from setup
- Can create a resource in the pool tenant
- Verifies isolation from other pool tenants

**File**: Add a describe block in the tenant_pool_test.exs

**Verify**: `mix test test/support/tenant_pool_test.exs`

## Step 8: Update test-architecture.md

**File**: `docs/knowledge/test-architecture.md`

Add concurrency groups section:
- How to use `async: {:group, :pool_a}`
- Available groups
- When to use groups vs async: true
- Pool context auto-injection behavior

**Verify**: Read the doc for accuracy

## Step 9: Full suite

Run `mix test` to verify nothing is broken.

## Testing Strategy

| What | Tier | How |
|------|------|-----|
| TenantPool.provision!/1 | Resource (DB) | Verify schemas exist in pg |
| TenantPool.checkout/1 | Resource | Verify context fields |
| TenantPool.teardown!/0 | Resource | Verify schemas dropped |
| Group sandbox integration | Integration | Test file with async: {:group, _} |
| ConnCase context injection | Integration | Verify context keys in test |
