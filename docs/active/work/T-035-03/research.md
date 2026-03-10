# T-035-03 Research: Shared Tenant Pool

## Goal

Provision N tenant schemas at suite start, expose them to test files via a pool mechanism, and integrate with ExUnit's concurrency group configuration. This enables parallelizing DB-touching tests that currently run serially.

## Existing Infrastructure

### Schema Template (T-035-01 — done)

`test/support/schema_template.ex` provides:
- `setup!/0` — creates a `__test_template__` schema, runs migrations, installs PL/pgSQL `clone_tenant_schema(source, target)` function
- `clone!(slug)` — clones template to `tenant_{slug}` in ~5-15ms (vs ~231ms migration)
- `teardown!/0` — drops template schema and clone function

Already wired in `test_helper.exs`:
```elixir
Haul.Test.SchemaTemplate.setup!()
ExUnit.after_suite(fn _ -> Haul.Test.SchemaTemplate.teardown!() end)
```

### Factories (`test/support/factories.ex`)

- `build_authenticated_context_fast/1` — uses `SchemaTemplate.clone!` + `skip_tenant_provision` flag
- `build_authenticated_context/1` — runs full migrations (slower)
- `ensure_operator_tenant!/0` — creates shared operator company once at suite start, stores in Application env
- `operator_context/0` — retrieves the pre-created operator context

### Test Cases

- `Haul.DataCase` — `setup_sandbox/1` calls `Sandbox.start_owner!` with `shared: not tags[:async]`
- `HaulWeb.ConnCase` — delegates to `DataCase.setup_sandbox/1`, adds conn

### Current test_helper.exs flow

1. Cleanup stale data (all tenant schemas except shared-test-co, admin_users, companies)
2. Pre-create operator company + tenant + seed content
3. Start ExUnit (exclude `:baml_live`)
4. Set sandbox to `:manual` mode
5. Setup SchemaTemplate + after_suite teardown

### Concurrency Groups (ExUnit 1.18+)

Elixir 1.19.5 is installed. ExUnit concurrency groups are available.

Syntax: `use ExUnit.Case, async: {:group, :group_name}`
- All files in a group run serially with each other
- Different groups run in parallel with each other
- Each group shares a single sandbox connection

### ProvisionTenant Change

`lib/haul/accounts/changes/provision_tenant.ex`:
- `change/3` checks `Application.get_env(:haul, :skip_tenant_provision)` — if true, skips schema creation
- `tenant_schema/1` derives `tenant_{slug}` from company slug
- The skip flag is global (Application env), noted as unsafe for concurrent async tests in T-035-01 review

### Async-Unlock (T-033-05 — done)

Flipped 96 test files to `async: true`. Key changes:
- Created `ensure_operator_tenant!/0` for shared operator company
- Wall-clock time: 77.3s → 8.5-19s
- Tests use `build_authenticated_context` per-test for isolation

## Key Files

| File | Role |
|------|------|
| `test/test_helper.exs` | Suite bootstrap — cleanup, operator, ExUnit.start, sandbox, template |
| `test/support/schema_template.ex` | PL/pgSQL clone function for fast tenant provisioning |
| `test/support/factories.ex` | Factory functions including `build_authenticated_context_fast` |
| `test/support/data_case.ex` | DataCase with sandbox setup |
| `test/support/conn_case.ex` | ConnCase with sandbox + conn setup |
| `lib/haul/accounts/changes/provision_tenant.ex` | Tenant schema provisioning change |

## Constraints

1. **Sandbox mode**: Concurrency groups need careful sandbox configuration. Each group needs its own sandbox connection that is shared among all tests in the group.
2. **Schema cloning outside sandbox**: `clone!` runs DDL (CREATE TABLE) which can't be inside a sandbox transaction. Pool schemas must be created at suite start before sandbox mode is set.
3. **Cleanup**: Pool schemas need cleanup on suite exit, but must survive the entire test run.
4. **Skip flag thread safety**: The `:skip_tenant_provision` Application env flag is global — safe only because pool provisioning happens at suite start (single-threaded).
5. **Operator tenant**: Already pre-created at suite start. Pool tenants are separate — they're for test files that need their own tenant for writes.

## ExUnit Group Mechanics

With `async: {:group, :tenant_a}`:
- ExUnit assigns all `:tenant_a` files to the same "partition"
- Within a partition, tests run serially (same as `async: false`)
- Different partitions run in parallel (like `async: true`)
- The sandbox for a group must be `shared: true` (all tests in the group share the connection)

This means `setup_sandbox` needs to detect group tags and configure accordingly.
