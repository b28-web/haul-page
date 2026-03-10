# T-025-02 Structure: Shared Test Tenant

## Files Created

### `test/support/shared_tenant.ex`
Module: `Haul.Test.SharedTenant`

Public API:
- `provision!/0` — Creates a company, provisions tenant schema, registers owner user, generates JWT. Stores result in Application env. Idempotent (no-op if already provisioned).
- `get!/0` — Returns the stored context map `%{company, tenant, user, token}`. Raises if not provisioned.
- `cleanup!/0` — Drops the tenant schema, deletes company record, clears Application env.

Implementation:
- Uses `HaulWeb.ConnCase.create_authenticated_context/1` for consistency.
- Company name: `"Shared Test Co"` (fixed, predictable).
- Runs in `:auto` sandbox mode temporarily (same pattern as `setup_all_authenticated_context`).
- Stores in `Application.put_env(:haul, :shared_test_tenant, ctx)`.

## Files Modified

### `test/test_helper.exs`
Add after `Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)`:
1. Call `Haul.Test.SharedTenant.provision!()` to create the shared tenant.
2. Register `ExUnit.after_suite(fn _ -> Haul.Test.SharedTenant.cleanup!() end)` for teardown.

### `test/support/conn_case.ex`
Add helper function:
- `shared_test_tenant/0` — Delegates to `Haul.Test.SharedTenant.get!/0`. Imported via `using` block so test files can call it directly.

### Test files migrated (9 files)
Each file's `setup_all` block changes from:
```elixir
setup_all do
  ctx = setup_all_authenticated_context(...)
  on_exit(fn -> cleanup_persistent_tenants(ctx) end)
  %{ctx: ctx}
end
```
To:
```elixir
setup_all do
  %{ctx: shared_test_tenant()}
end
```

Files:
1. `test/haul_web/live/app/services_live_test.exs`
2. `test/haul_web/live/app/gallery_live_test.exs`
3. `test/haul_web/live/app/endorsements_live_test.exs`
4. `test/haul_web/live/app/site_config_live_test.exs`
5. `test/haul_web/live/app/onboarding_live_test.exs`
6. `test/haul_web/live/app/billing_live_test.exs`
7. `test/haul_web/live/app/billing_qa_test.exs`
8. `test/haul_web/live/app/domain_settings_live_test.exs`
9. `test/haul_web/live/app/domain_qa_test.exs`

## Files NOT Modified

- `test/haul_web/live/app/dashboard_live_test.exs` — keeps 3 private role contexts
- `test/haul/tenant_isolation_test.exs` — keeps 2 private tenants
- `test/haul/accounts/security_test.exs` — keeps 2 private companies
- `test/haul_web/live/app/signup_live_test.exs` — different pattern
- `test/haul_web/live/app/login_live_test.exs` — doesn't use setup_all
- `test/haul_web/live/app/signup_flow_test.exs` — different pattern

## Module Boundaries

```
test_helper.exs
  └── Haul.Test.SharedTenant.provision!()     # Once, at boot
  └── ExUnit.after_suite → SharedTenant.cleanup!()

HaulWeb.ConnCase
  └── shared_test_tenant/0                     # Helper for test files

Test files (9)
  └── setup_all: shared_test_tenant()          # Opt-in
  └── setup: sandbox + conn (unchanged)        # Per-test isolation preserved
```

## Ordering

1. Create `shared_tenant.ex` first (no dependencies on other changes).
2. Modify `test_helper.exs` (depends on shared_tenant.ex existing).
3. Add `shared_test_tenant/0` to `conn_case.ex`.
4. Migrate test files (each independent, can be done in any order).
5. Verify with full test suite.
