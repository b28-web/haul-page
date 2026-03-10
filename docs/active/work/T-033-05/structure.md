# T-033-05 Structure: async-unlock

## Files Modified

### 1. `test/support/conn_case.ex`
- Line 49: Change `%{name: "Test Co"}` → `%{name: "Test Co #{System.unique_integer([:positive])}"}`
- This single change unblocks all ConnCase and DataCase files that call `create_authenticated_context`

### 2. DataCase test files — flip `async: false` → `async: true` (23 files)

```
test/haul/accounts/company_test.exs
test/haul/accounts/user_test.exs
test/haul/accounts/security_test.exs
test/haul/ai/edit_applier_test.exs
test/haul/ai/provisioner_test.exs
test/haul/content/endorsement_test.exs
test/haul/content/gallery_item_test.exs
test/haul/content/page_test.exs
test/haul/content/seeder_test.exs
test/haul/content/service_test.exs
test/haul/content/site_config_test.exs
test/haul/onboarding_test.exs
test/haul/operations/changes/enqueue_notifications_test.exs
test/haul/operations/job_test.exs
test/haul/tenant_isolation_test.exs
test/haul/workers/check_dunning_grace_test.exs
test/haul/workers/provision_cert_test.exs
test/haul/workers/provision_site_test.exs
test/haul/workers/send_booking_email_test.exs
test/haul/workers/send_booking_sms_test.exs
test/mix/tasks/haul/onboard_test.exs
```

### 3. ConnCase test files — flip `async: false` → `async: true` (18 files)

```
test/haul_web/controllers/billing_webhook_controller_test.exs
test/haul_web/controllers/page_controller_test.exs
test/haul_web/controllers/webhook_controller_test.exs
test/haul_web/live/admin/account_detail_live_test.exs
test/haul_web/live/admin/accounts_live_test.exs
test/haul_web/live/app/dashboard_live_test.exs
test/haul_web/live/app/domain_settings_live_test.exs
test/haul_web/live/app/endorsements_live_test.exs
test/haul_web/live/app/gallery_live_test.exs
test/haul_web/live/app/login_live_test.exs
test/haul_web/live/app/onboarding_live_test.exs
test/haul_web/live/app/services_live_test.exs
test/haul_web/live/app/site_config_live_test.exs
test/haul_web/live/booking_live_autocomplete_test.exs
test/haul_web/live/booking_live_test.exs
test/haul_web/live/booking_live_upload_test.exs
test/haul_web/live/payment_live_test.exs
test/haul_web/live/scan_live_test.exs
test/haul_web/live/tenant_hook_test.exs
test/haul_web/smoke_test.exs
```

### 4. ExUnit.Case test file — flip `async: false` → `async: true` (1 file)

```
test/haul/ai/chat_test.exs
```

### 5. Files remaining async: false (documented)

```
# Rate limiter blocker (→ T-035-02)
test/haul_web/live/app/billing_live_test.exs
test/haul_web/live/app/signup_flow_test.exs
test/haul_web/live/app/signup_live_test.exs
test/haul_web/live/chat_live_test.exs
test/haul_web/live/preview_edit_test.exs
test/haul_web/plugs/proxy_routes_test.exs

# Temp file creation in /tmp
test/mix/tasks/haul/test_pyramid_test.exs
```

## No New Files Created

All changes are modifications to existing files. No new modules, no new test helpers.

## Module Boundaries

No module boundaries change. The only production-relevant change is the uniqueness fix in ConnCase — which is test infrastructure, not production code.

## Ordering

1. Fix `create_authenticated_context` uniqueness (must come first — enables everything else)
2. Flip DataCase files (simpler, fewer dependencies)
3. Flip ConnCase files (more complex, may surface issues)
4. Flip chat_test.exs
5. Run full suite 3× to verify no flakiness
