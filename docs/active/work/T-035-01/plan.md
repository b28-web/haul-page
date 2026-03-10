# T-035-01 Plan: Schema Template Clone

## Step 1: Create SchemaTemplate module

Create `test/support/schema_template.ex` with:
- `setup!/0` — checkout repo, auto mode, create `__test_template__` schema, run migrations, install PL/pgSQL clone function, checkin
- `clone!/1` — run `SELECT clone_tenant_schema('__test_template__', 'tenant_{slug}')` via raw SQL, return tenant string
- `teardown!/0` — drop `__test_template__` schema, drop the clone function
- Inline PL/pgSQL function as a module attribute or heredoc

Verify: `mix run -e "Haul.Test.SchemaTemplate.setup!(); IO.puts(\"OK\")"` (approximate — may need test env)

## Step 2: Add skip flag to ProvisionTenant

Add guard clause to `lib/haul/accounts/changes/provision_tenant.ex`:
```elixir
if Application.get_env(:haul, :skip_tenant_provision), do: changeset, else: ...
```

Verify: existing tests still pass (`mix test --stale`)

## Step 3: Update test_helper.exs

Add template setup after sandbox mode line:
```elixir
Haul.Test.SchemaTemplate.setup!()
ExUnit.after_suite(fn _ -> Haul.Test.SchemaTemplate.teardown!() end)
```

Verify: `mix test --stale` (template should be created/torn down transparently)

## Step 4: Add build_authenticated_context_fast to Factories

Add new function that:
1. Sets `:skip_tenant_provision` app env
2. Creates company
3. Deletes env flag
4. Clones template
5. Creates user + token

Verify: write a small test or benchmark script that uses the fast path

## Step 5: Benchmark and verify structural equivalence

Write a benchmark script:
1. Time `build_authenticated_context/0` (migration path) — expect ~231ms
2. Time `build_authenticated_context_fast/0` (clone path) — expect ≤50ms
3. Compare table structures: query `information_schema.columns` for both schemas, assert identical

Verify: benchmark shows ≤50ms, structures match

## Step 6: Run full test suite

Run `mix test --stale` to verify no regressions from the ProvisionTenant flag change.

## Testing Strategy

- No new test FILE needed — this is test infrastructure
- Verify via benchmark script (inline or tmp/)
- Verify structural equivalence via information_schema comparison
- Verify all existing tests pass with `mix test --stale`
- Before review: `mix test` full suite (note pre-existing failures)
