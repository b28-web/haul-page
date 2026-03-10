# T-027-03 Structure: File-Level Changes

## No new files created. No files deleted.

## Modified files (15 total)

### Group 1: Cleanup-only (5 files)
Replace manual SQL on_exit with `cleanup_all_tenants()`. Remove unused aliases.

- `test/haul/onboarding_test.exs` — replace 10-line on_exit with 1-line
- `test/haul/ai/edit_applier_test.exs` — replace 10-line on_exit with 1-line
- `test/haul/ai/provisioner_test.exs` — replace 10-line on_exit with 1-line
- `test/haul/workers/provision_site_test.exs` — replace 10-line on_exit with 1-line
- `test/mix/tasks/haul/onboard_test.exs` — replace 10-line on_exit with 1-line

### Group 2: Setup + cleanup (6 files)
Replace inline Company creation + ProvisionTenant + cleanup with factory calls.

- `test/haul/content/seeder_test.exs` — replace setup block, remove `ProvisionTenant`/`Company` aliases
- `test/haul/operations/changes/enqueue_notifications_test.exs` — replace setup block, remove aliases
- `test/haul/workers/send_booking_email_test.exs` — replace setup, use `build_job`, remove aliases
- `test/haul/workers/send_booking_sms_test.exs` — replace setup, use `build_job`, remove aliases
- `test/haul/workers/check_dunning_grace_test.exs` — replace Company create with `build_company`, replace cleanup
- `test/haul/workers/provision_cert_test.exs` — replace Company create with `build_company`, replace cleanup

### Group 3: Multi-tenant setup_all (2 files)
Replace setup_all helpers with factory calls. Remove local helper functions.

- `test/haul/accounts/security_test.exs` — remove `register_user`/`set_role` helpers, use `build_company`+`provision_tenant`+`build_user`
- `test/haul/tenant_isolation_test.exs` — remove 6 local helpers (~50 lines), use factory functions in setup_all

### Group 4: Partial migration (2 files)
- `test/haul/accounts/company_test.exs` — only replace on_exit cleanup (Company creation is what's being tested)
- `test/haul/accounts/user_test.exs` — replace setup Company+ProvisionTenant with factories, replace cleanup, keep local `register_user` (tests registration behavior directly)

## Change ordering

1. Group 1 first (lowest risk, cleanup-only)
2. Group 2 next (setup + cleanup, straightforward)
3. Group 4 (partial, need care with company_test)
4. Group 3 last (most complex, multi-tenant setup_all)

## No changes to factories.ex or shared_tenant.ex or data_case.ex or conn_case.ex
