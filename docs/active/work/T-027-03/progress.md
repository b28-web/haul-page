# T-027-03 Progress: Migrate DataCase Tests to Factories

## Completed

### Step 1: Group 1 — Cleanup-only (5 files) ✓
- `test/haul/onboarding_test.exs` — replaced manual SQL on_exit
- `test/haul/ai/edit_applier_test.exs` — replaced manual SQL on_exit
- `test/haul/ai/provisioner_test.exs` — replaced manual SQL on_exit
- `test/haul/workers/provision_site_test.exs` — replaced manual SQL on_exit
- `test/mix/tasks/haul/onboard_test.exs` — replaced manual SQL on_exit
- **37 tests, 0 failures**

### Step 2: Group 2 — Setup + cleanup (6 files) ✓
- `test/haul/content/seeder_test.exs` — replaced inline Company+ProvisionTenant, removed aliases
- `test/haul/operations/changes/enqueue_notifications_test.exs` — same
- `test/haul/workers/send_booking_email_test.exs` — replaced setup, used build_booking_job
- `test/haul/workers/send_booking_sms_test.exs` — same
- `test/haul/workers/check_dunning_grace_test.exs` — replaced Company create with build_company
- `test/haul/workers/provision_cert_test.exs` — same
- **21 tests, 0 failures**

### Deviation: build_job → build_booking_job
A pre-commit hook renamed `build_job` to `build_booking_job` in factories.ex to avoid conflict with Oban.Testing's `build_job`. The rename propagated to all test files automatically. For files using Oban.Testing (send_booking_email_test, send_booking_sms_test), we use fully-qualified `Haul.Test.Factories.build_booking_job/2`.

### Step 3: Group 4 — Partial migration (2 files) ✓
- `test/haul/accounts/company_test.exs` — replaced on_exit cleanup only
- `test/haul/accounts/user_test.exs` — replaced setup with factories, kept local register_user
- **24 tests, 0 failures**

### Step 4: Group 3 — Multi-tenant setup_all (2 files) ✓
- `test/haul/accounts/security_test.exs` — removed register_user/set_role helpers, used build_company+provision_tenant+build_user
- `test/haul/tenant_isolation_test.exs` — removed 6 local helpers, used factory functions throughout
- **21 tests, 0 failures**
- Note: crew user needed explicit `role: :crew` since `build_user` defaults to `:owner`

### Step 5: Full suite verification ✓
- `mix test test/haul/ test/mix/` — 390 tests, 0 failures
- Full suite (`mix test`) — 845 tests, 98 failures. The 98 failures are ALL in ConnCase web tests (HaulWeb.App.BillingQATest ordering issue), pre-existing from T-027-01/02 staged changes. Not related to this ticket.
