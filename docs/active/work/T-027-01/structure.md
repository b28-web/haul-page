# T-027-01 Structure: Core Factories

## Files

### Create: `test/support/factories.ex`

Module: `Haul.Test.Factories`

Public functions:
- `build_company(attrs \\ %{})` — creates Company with unique name via `:create_company` action
- `provision_tenant(company)` — calls `ProvisionTenant.tenant_schema/1`, returns tenant string
- `build_user(tenant, attrs \\ %{})` — registers user, sets role, generates JWT. Returns `%{user: user, token: token}`
- `build_authenticated_context(attrs \\ %{})` — orchestrates build_company + provision_tenant + build_user. Returns `%{company, tenant, user, token}`
- `build_admin_session(attrs \\ %{})` — creates AdminUser with bootstrap + complete_setup + sign_in. Returns `%{admin, token}`
- `cleanup_all_tenants()` — drops all `tenant_%` schemas except shared tenant

No imports from ConnCase or DataCase. Directly uses Ash, Ecto, AshAuthentication, Bcrypt.

### Modify: `test/support/conn_case.ex`

- `create_authenticated_context/1` → delegate to `Haul.Test.Factories.build_authenticated_context/1`
- `create_admin_session/0` → delegate to `Haul.Test.Factories.build_admin_session/0`
- `cleanup_tenants/0` → delegate to `Haul.Test.Factories.cleanup_all_tenants/0`
- Remove alias blocks from inside `create_authenticated_context/1` and `create_admin_session/0`

### Modify: `test/support/data_case.ex`

- Add `import Haul.Test.Factories` to `using` block

### Modify: `test/support/shared_tenant.ex`

- Change `HaulWeb.ConnCase.create_authenticated_context/1` → `Haul.Test.Factories.build_authenticated_context/1`

## Ordering

1. Create factories.ex (no dependents yet)
2. Update SharedTenant to use Factories (it's called from test_helper.exs before ConnCase is loaded — wait, ConnCase IS loaded by then since it's in test/support/. Actually SharedTenant currently calls ConnCase which works fine. Switching to Factories will also work since factories.ex is in test/support/ too.)
3. Update ConnCase to delegate
4. Update DataCase to import
5. Run full suite to verify
