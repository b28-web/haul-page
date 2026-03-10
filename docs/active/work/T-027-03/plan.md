# T-027-03 Plan: Implementation Steps

## Step 1: Group 1 — Cleanup-only files (5 files)

Replace manual SQL on_exit blocks with `cleanup_all_tenants()` in:
- `test/haul/onboarding_test.exs`
- `test/haul/ai/edit_applier_test.exs`
- `test/haul/ai/provisioner_test.exs`
- `test/haul/workers/provision_site_test.exs`
- `test/mix/tasks/haul/onboard_test.exs`

Verify: `mix test test/haul/onboarding_test.exs test/haul/ai/ test/haul/workers/provision_site_test.exs test/mix/tasks/haul/onboard_test.exs`

## Step 2: Group 2 — Setup + cleanup files (6 files)

### 2a: seeder_test + enqueue_notifications_test
Replace inline Company+ProvisionTenant with `build_company`+`provision_tenant`. Replace cleanup. Remove unused aliases.

Verify: `mix test test/haul/content/seeder_test.exs test/haul/operations/changes/enqueue_notifications_test.exs`

### 2b: send_booking_email_test + send_booking_sms_test
Same pattern + replace inline Job creation with `build_job`.

Verify: `mix test test/haul/workers/send_booking_email_test.exs test/haul/workers/send_booking_sms_test.exs`

### 2c: check_dunning_grace_test + provision_cert_test
Replace inline Company create with `build_company`. Replace cleanup. Keep Company update calls (test-specific attrs).

Verify: `mix test test/haul/workers/check_dunning_grace_test.exs test/haul/workers/provision_cert_test.exs`

## Step 3: Group 4 — Partial migration (2 files)

### 3a: company_test
Only replace the on_exit cleanup block. Keep all Company creation in test bodies.

### 3b: user_test
Replace setup Company+ProvisionTenant with `build_company`+`provision_tenant`. Replace cleanup. Keep local `register_user`.

Verify: `mix test test/haul/accounts/`

## Step 4: Group 3 — Multi-tenant setup_all (2 files)

### 4a: security_test
- Remove `register_user` and `set_role` private helpers
- In setup_all: use `build_company`, `provision_tenant`, `build_user` with role attr
- Extract `.user` from `build_user` result maps
- Keep `cleanup_persistent_tenants` for setup_all cleanup

### 4b: tenant_isolation_test
- Remove all 6 local helpers (~50 lines)
- In setup_all: use `build_company`+`provision_tenant`, `build_user`, `build_job`, `build_site_config`, `build_service`, `build_gallery_item`, `build_endorsement`
- Keep `cleanup_persistent_tenants` for setup_all cleanup
- Keep `ProvisionTenant` alias if needed for assertions, else remove

Verify: `mix test test/haul/accounts/security_test.exs test/haul/tenant_isolation_test.exs`

## Step 5: Full suite verification

Run `mix test` 3 times with different seeds to confirm stability.

## Testing strategy

- Targeted tests after each step (~15s each)
- Full suite after all changes (~27s)
- No test behavior changes — assertions identical before and after
