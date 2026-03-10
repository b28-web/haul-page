# T-034-02 Plan: setup_all Quick Wins

## Step 1: Convert page_controller_test.exs

1. Replace `setup do` with `setup_all do`:
   - Add `Sandbox.checkout(Repo)` + `Sandbox.mode(Repo, :auto)`
   - Use `Factories.build_company(%{slug: operator_slug})` instead of inline Ash create
   - Provision tenant + seed content (same as before)
   - Add `on_exit` that re-checkouts sandbox in :auto mode and cleans up tenants
   - Revert sandbox to `:manual` after setup_all data creation
   - Return `%{tenant: tenant, host: host}`
2. Add `setup do` that builds conn per test
3. Verify: `mix test test/haul_web/controllers/page_controller_test.exs`

## Step 2: Convert onboarding_live_test.exs

1. Replace top-level `setup do` with `setup_all do`:
   - Sandbox checkout + :auto mode
   - `create_authenticated_context()` → `Factories.build_authenticated_context()`
   - `ProvisionTenant.tenant_schema(company.slug)` — already called by factory
   - `Seeder.seed!(tenant)` — seed content once
   - `on_exit` cleanup
   - Revert to :manual
   - Return `%{ctx: ctx}` (company, tenant, user, token)
2. Add `setup %{ctx: ctx} do` that builds conn per test
3. Keep "public pages after CLI onboarding" describe's `setup do` block unchanged
4. Verify: `mix test test/haul_web/live/app/onboarding_live_test.exs`

## Step 3: Convert accounts_live_test.exs

1. Replace `setup [:setup_admin, :create_companies]` with module-level `setup_all do`:
   - Sandbox checkout + :auto mode
   - Create admin via `Factories.build_admin_session()`
   - Create 2 companies via `Factories.build_company(%{name: "Alpha Hauling"})` etc.
   - `on_exit` cleanup (drop tenants + delete companies)
   - Revert to :manual
   - Return `%{admin_token: token, company1: company1, company2: company2}`
2. Simplify `admin_conn/2` to use the shared token
3. Remove `setup_admin/1` and `create_companies/1` defp functions
4. Keep "accounts list security" describe unchanged
5. Keep `setup [:setup_admin, :create_companies]` → change to just use setup_all context
6. Verify: `mix test test/haul_web/live/admin/accounts_live_test.exs`

## Step 4: Update test-architecture.md

1. Expand the setup_all section with the concrete pattern
2. Add note about sandbox `:auto` → `:manual` revert for ConnCase compatibility
3. Reference the converted files as examples

## Step 5: Run full test suite

1. `mix test` — verify all 975 tests pass
2. Note any timing improvements

## Testing Strategy

- After each file conversion: `mix test <file>` to verify that specific file
- After all conversions: `mix test --stale` to catch any cascade issues
- Before review: `mix test` full suite
