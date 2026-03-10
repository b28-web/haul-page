# T-027-01 Research: Core Factories

## Current State

### Test helper architecture

Two case templates exist:
- **`HaulWeb.ConnCase`** (`test/support/conn_case.ex`) — for LiveView/controller tests. Contains `create_authenticated_context/1`, `create_admin_session/0`, `log_in_user/2`, `log_in_admin/2`, `cleanup_tenants/0`, `shared_test_tenant/0`, `setup_all_authenticated_context/1`, `cleanup_persistent_tenants/1`.
- **`Haul.DataCase`** (`test/support/data_case.ex`) — for domain-level tests. Contains only `setup_sandbox/1` and `errors_on/1`. No factory helpers.
- **`Haul.Test.SharedTenant`** (`test/support/shared_tenant.ex`) — provisions a single shared tenant for setup_all usage.

### Duplication patterns

**Pattern 1: Company + tenant provisioning (9+ files)**
DataCase tests duplicate a ~15-line block: create company via Ash, call `ProvisionTenant.tenant_schema(company.slug)`, set up on_exit cleanup. Found in:
- `test/haul/content/` — site_config_test, service_test, page_test, gallery_item_test, endorsement_test, seeder_test (6 files)
- `test/haul/operations/` — job_test, enqueue_notifications_test (2 files)
- `test/haul_web/smoke_test.exs` (1 file)

**Pattern 2: User registration helper (3 files)**
Private `register_user/2` functions duplicated across:
- `test/haul/accounts/user_test.exs`
- `test/haul/accounts/security_test.exs`
- `test/haul/tenant_isolation_test.exs`

**Pattern 3: Company creation helper (3 files)**
Private `create_company/2` functions duplicated across plug tests:
- `test/haul_web/plugs/tenant_resolver_test.exs`
- `test/haul_web/plugs/proxy_tenant_resolver_test.exs`
- `test/haul_web/plugs/proxy_routes_test.exs`

### Key dependencies

- `Haul.Accounts.Changes.ProvisionTenant` — `tenant_schema/1` runs DDL to create PostgreSQL schema
- `Haul.Accounts.Company` — Ash resource, `:create_company` action
- `Haul.Accounts.User` — Ash resource, `:register_with_password` action
- `AshAuthentication.Jwt` — `token_for_user/1` generates JWT
- `Haul.Admin.AdminUser` — Ash resource, `:create_bootstrap` + `:complete_setup` + `:sign_in_with_password`
- `Bcrypt` — used for admin password hashing

### ConnCase already has the right API

`create_authenticated_context/1` and `create_admin_session/0` are well-designed. The ticket asks to extract the logic into a standalone `Haul.Test.Factories` module and have ConnCase delegate to it. DataCase tests can then import Factories directly.

### SharedTenant depends on ConnCase

`SharedTenant.provision!/0` calls `HaulWeb.ConnCase.create_authenticated_context/1`. After this ticket, it should call `Haul.Test.Factories.build_authenticated_context/1` instead.

## Constraints

- No test files change yet (T-027-02 and T-027-03 handle migration)
- ConnCase API must remain identical (delegations preserve existing callers)
- DataCase gains `import Haul.Test.Factories` in its `using` block
- All 845+ tests must pass unchanged
