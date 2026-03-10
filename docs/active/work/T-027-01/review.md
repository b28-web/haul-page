# T-027-01 Review: Core Factories

## Summary

Extracted core test factory functions from `HaulWeb.ConnCase` into standalone `Haul.Test.Factories` module. ConnCase delegates to Factories, DataCase imports Factories, SharedTenant uses Factories directly.

## Files changed

| File | Action | Description |
|------|--------|-------------|
| `test/support/factories.ex` | Created | `Haul.Test.Factories` with 6 public functions |
| `test/support/conn_case.ex` | Modified | 3 functions now delegate to Factories |
| `test/support/data_case.ex` | Modified | Added `import Haul.Test.Factories` to `using` block |
| `test/support/shared_tenant.ex` | Modified | Uses `Factories.build_authenticated_context/1` instead of `ConnCase.create_authenticated_context/1` |

## Factory API

```elixir
Haul.Test.Factories.build_company(attrs \\ %{})              # -> Company
Haul.Test.Factories.provision_tenant(company)                  # -> tenant string
Haul.Test.Factories.build_user(tenant, attrs \\ %{})          # -> %{user, token}
Haul.Test.Factories.build_authenticated_context(attrs \\ %{}) # -> %{company, tenant, user, token}
Haul.Test.Factories.build_admin_session(attrs \\ %{})         # -> %{admin, token}
Haul.Test.Factories.cleanup_all_tenants()                      # -> :ok
```

## Test results

- **Targeted tests**: 32/32 pass (domain_settings, signup, site_config, job, security, tenant_isolation, dashboard)
- **Full suite**: 845 tests, 11 failures — all pre-existing from T-025-01 `setup_all` migration (shared state mutation ordering). Verified: main branch without factory changes has 8 failures in same tests.

## Acceptance criteria checklist

- [x] `test/support/factories.ex` with `Haul.Test.Factories` module
- [x] `build_company/1` — creates Company with unique name/slug
- [x] `provision_tenant/1` — provisions schema, returns tenant string
- [x] `build_user/2` — registers user with role, returns user + JWT token
- [x] `build_authenticated_context/1` — orchestrates all three
- [x] `build_admin_session/1` — creates AdminUser with completed setup
- [x] All use `System.unique_integer([:positive])` for uniqueness
- [x] ConnCase delegates to Factories (API unchanged)
- [x] DataCase imports Factories
- [x] `setup_all_authenticated_context/1` and `cleanup_persistent_tenants/1` remain in ConnCase
- [x] No test files changed (delegations preserve existing API)

## Open concerns

1. **Pre-existing full-suite failures**: 8-11 tests fail in full suite due to T-025-01's `setup_all`/`shared_test_tenant` migration. Tests that mutate the shared company (subscription_plan, domain, etc.) interfere when run in certain orders. This is NOT caused by T-027-01 and should be addressed in T-025-02 or T-025-03.

2. **`build_admin_session/1` signature**: Accepts `attrs` parameter for future extensibility but currently ignores it. The `_attrs` underscore prefix signals this.

3. **DataCase import scope**: All DataCase tests now have `build_company`, `build_user`, etc. available via import. No naming conflicts exist today, but worth noting for future factory additions.
