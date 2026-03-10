# T-025-03 Progress: Timing Verification

## Changes Made

### Infrastructure (test/support/)

1. **`test/support/conn_case.ex`** — Updated to delegate to Factories module:
   - Added `import Haul.Test.Factories` to `using` block
   - `create_authenticated_context/1` delegates to `Factories.build_authenticated_context/1`
   - `create_admin_session/0` delegates to `Factories.build_admin_session/0`
   - Added `shared_test_tenant/0` — reads from `SharedTenant.get!()`
   - Added `setup_all_authenticated_context/1` — creates context outside sandbox
   - Added `cleanup_persistent_tenants/1` — uses raw Postgrex (no global sandbox mode switch)
   - Added `cleanup_tenants/0` — delegates to `Factories.cleanup_all_tenants/0`

2. **`test/support/data_case.ex`** — Added `import Haul.Test.Factories` to `using` block

3. **`test/test_helper.exs`** — Added `SharedTenant.provision!()` at boot + `after_suite` cleanup

### Shared Tenant Migration (4 ConnCase files)

Converted from per-test `create_authenticated_context()` to `setup_all { shared_test_tenant() }`:
- `gallery_live_test.exs` — replaced inline `create_item/2` with `build_gallery_item/2`
- `services_live_test.exs` — replaced inline `create_service/2` with `build_service/2`
- `endorsements_live_test.exs` — replaced inline `create_endorsement/2` with `build_endorsement/2`
- `site_config_live_test.exs`

### Per-Test Setup (company-mutating files, no cleanup)

Kept per-test setup because tests mutate company state, removed `on_exit` cleanup:
- `billing_live_test.exs`, `billing_qa_test.exs`
- `domain_settings_live_test.exs`, `domain_qa_test.exs`
- `onboarding_live_test.exs`
- `dashboard_live_test.exs` (3 role contexts)

### Factory Migration (18 DataCase files)

Replaced inline company/tenant/resource creation with factory functions, removed
`on_exit` DROP SCHEMA cleanup:
- All files in `test/haul/content/`, `test/haul/accounts/`, `test/haul/operations/`,
  `test/haul/workers/`, `test/haul/ai/`

### Cleanup Removal (remaining ConnCase + controller files)

Removed `on_exit` cleanup from per-test setup blocks:
- Controllers, booking live tests, payment, scan, tenant_hook, smoke, preview_edit,
  provision_qa, proxy_qa, superadmin_qa, signup, login, onboard task

### Build Job Rename

Renamed `build_job/2` → `build_booking_job/2` in `factories.ex` and all callers to
avoid conflict with `Oban.Testing.build_job/2`.

## Key Fix: on_exit Cleanup Removal

Root cause of seed-dependent flakiness: `on_exit(fn -> cleanup_all_tenants() end)` in
per-test `setup` blocks. These callbacks ran DDL (`DROP SCHEMA CASCADE`) inside sandbox
transactions, taking exclusive locks on PostgreSQL system catalogs. ExUnit `on_exit`
callbacks run asynchronously, overlapping with the next module's tests. This caused
sandbox connection interference → JWT verification failures → login redirects in
shared_test_tenant modules.

Fix: remove ALL `on_exit` cleanup from per-test `setup` blocks. PostgreSQL transactional
DDL means sandbox rollback automatically undoes CREATE SCHEMA + migrations.
