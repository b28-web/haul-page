# T-035-01 Structure: Schema Template Clone

## Files Created

### `test/support/schema_template.ex`
New module: `Haul.Test.SchemaTemplate`

Public interface:
- `setup!()` — Create template schema, run migrations, install clone function. Called once in test_helper.exs.
- `clone!(slug)` — Clone template to `tenant_{slug}`. Returns tenant string. ~5-15ms.
- `teardown!()` — Drop template schema and clone function. Called in ExUnit.after_suite/1.

Internal:
- `install_clone_function!()` — Runs raw SQL to create `clone_tenant_schema` PL/pgSQL function.
- `@template_schema "__test_template__"` — Module attribute for template schema name.

### `test/support/clone_tenant_schema.sql` (optional)
The PL/pgSQL function as a standalone SQL file for readability. Or inline in schema_template.ex as a heredoc. Prefer inline for simplicity.

## Files Modified

### `test/test_helper.exs`
Add after `Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)`:
```elixir
Haul.Test.SchemaTemplate.setup!()
ExUnit.after_suite(fn _ -> Haul.Test.SchemaTemplate.teardown!() end)
```

### `lib/haul/accounts/changes/provision_tenant.ex`
Add skip flag check at top of `change/3`:
```elixir
def change(changeset, _opts, _context) do
  if Application.get_env(:haul, :skip_tenant_provision) do
    changeset
  else
    # existing after_action logic
  end
end
```

### `test/support/factories.ex`
Add new function `build_authenticated_context_fast/1`:
- Sets `:skip_tenant_provision` flag
- Creates company via `build_company/1` (ProvisionTenant skipped)
- Clears flag
- Calls `SchemaTemplate.clone!(company.slug)`
- Creates user + token via `build_user/2`
- Returns same shape as `build_authenticated_context/1`

## Files NOT Modified

- `test/support/conn_case.ex` — No changes needed
- `test/support/data_case.ex` — No changes needed
- `test/support/shared_tenant.ex` — Not affected (uses its own provisioning)
- No test files changed in this ticket — just adding the infrastructure

## Module Boundaries

```
test_helper.exs
  → Haul.Test.SchemaTemplate.setup!()  (once per suite)

Haul.Test.Factories
  → build_authenticated_context_fast/1
    → build_company/1 (with skip flag)
    → Haul.Test.SchemaTemplate.clone!/1
    → build_user/2
```

## Ordering

1. Create `test/support/schema_template.ex`
2. Modify `lib/haul/accounts/changes/provision_tenant.ex` (skip flag)
3. Modify `test/test_helper.exs` (template setup)
4. Modify `test/support/factories.ex` (fast context builder)
5. Write benchmark test to verify ≤50ms
