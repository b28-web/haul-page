# T-033-05 Research: async-unlock

## Current State

### Test Distribution (post T-033-02/03/04)
- **Total test files:** 102
- **async: true:** 50 files (38 ExUnit.Case, 4 DataCase, 8 ConnCase)
- **async: false:** 50 files (2 ExUnit.Case, 25 DataCase, 23 ConnCase)
- **898 tests total** (post QA dedup), 77.3s baseline (last T-033-04 measurement)
- **Current measured run:** 22.4s (1.1s async, 21.3s sync) — 103 failures from slug conflicts

### Baseline Timing Issue
The 103 test failures are caused by `ConnCase.create_authenticated_context/1` using hardcoded `%{name: "Test Co"}` → slug "test-co". When tests run concurrently, unique constraint on slug fires. The factory `build_company/1` already uses `System.unique_integer` for uniqueness — ConnCase helper doesn't.

This is NOT a new regression — it manifests whenever async tests share the same DB and both call `create_authenticated_context`. Fix: make `create_authenticated_context` use unique company names (like `build_company` already does).

## Async Blockers by Category

### 1. ChatSandbox (FIXED in T-033-03)
- **Files:** chat_test, edit_applier_test, provisioner_test
- **Fix:** PID-keyed ETS with `$callers` ancestry chain
- **Status:** Ready to flip to async: true

### 2. Rate Limiter Global ETS (5 files)
- **Files:** billing_live_test, signup_flow_test, signup_live_test, proxy_routes_test, chat_live_test, preview_edit_test
- **Root cause:** `clear_rate_limits/0` calls `ets.delete_all_objects(Haul.RateLimiter)` — global wipe
- **Status:** T-035-02 is designated to fix this. However, we can implement a scoped fix here since it's blocking 5+ files from async.

### 3. Hardcoded Company Slug (ALL ConnCase + DataCase files)
- **Root cause:** `create_authenticated_context/1` uses `%{name: "Test Co"}` — always generates slug "test-co"
- **Impact:** Any two concurrent tests calling this function get unique constraint violations
- **Fix:** Use unique company names (like `build_company` factory does)

### 4. DDL Schema Creation (DataCase files)
- DataCase files that call `create_authenticated_context` or `build_authenticated_context` trigger `CREATE SCHEMA` per test
- DDL can't be sandboxed — two concurrent `CREATE SCHEMA` with same name conflict
- With unique company names → unique tenant names → no conflict
- Ecto sandbox handles row-level isolation for shared schemas

### 5. setup_all Shared Tenant Pattern
- Some files (page_controller_test, etc.) use `setup_all` with manual sandbox checkout
- These create a single tenant once and share it across all tests in the module
- Already async-compatible if the shared tenant has a unique name

## ExUnit Concurrency Groups
- Available since Elixir 1.18 (we're on 1.19.5)
- Syntax: `use ExUnit.Case, async: {:group, :group_name}`
- Tests within a group run serially; different groups run in parallel
- Useful for tests that must be serial within a shared tenant but can parallelize across tenants
- Currently zero usage in the codebase

## Key Infrastructure Files

| File | Purpose | Relevant to async |
|------|---------|-------------------|
| `test/support/conn_case.ex` | ConnCase template, `create_authenticated_context`, `clear_rate_limits` | Yes — hardcoded slug, global ETS wipe |
| `test/support/data_case.ex` | DataCase template, sandbox setup | Yes — `shared: not tags[:async]` already correct |
| `test/support/factories.ex` | Factory functions with unique names | Yes — already async-safe |
| `test/test_helper.exs` | ExUnit config, sandbox mode | Yes — may need concurrency group config |
| `lib/haul/rate_limiter.ex` | Global ETS rate limiter | Yes — global state blocker |
| `lib/haul/ai/chat/sandbox.ex` | PID-keyed chat mock | No — already fixed |

## Files Ready for async: true (No Blockers)

### ExUnit.Case (1 file)
- `test/haul/ai/chat_test.exs` — ChatSandbox fixed, ready

### DataCase (up to 25 files — after slug fix)
All 25 DataCase async:false files have no global state blocker other than the slug conflict:
- accounts/company_test, user_test, security_test
- content/endorsement_test, gallery_item_test, page_test, seeder_test, service_test, site_config_test
- onboarding_test
- operations/enqueue_notifications_test, job_test
- tenant_isolation_test
- workers/check_dunning_grace_test, provision_cert_test, provision_site_test, send_booking_email_test, send_booking_sms_test
- ai/edit_applier_test, provisioner_test
- mix/tasks/haul/onboard_test

### ConnCase (up to 18 files — after slug fix, excluding rate limiter files)
- controllers/billing_webhook_controller_test, page_controller_test, webhook_controller_test
- admin/account_detail_live_test, accounts_live_test
- app/dashboard_live_test, domain_settings_live_test, endorsements_live_test, gallery_live_test, login_live_test, onboarding_live_test, services_live_test, site_config_live_test
- booking_live_autocomplete_test, booking_live_test, booking_live_upload_test
- payment_live_test, scan_live_test, tenant_hook_test, smoke_test

### ConnCase (5 files — blocked by rate limiter)
- app/billing_live_test, signup_flow_test, signup_live_test
- chat_live_test, preview_edit_test
- proxy_routes_test

## Approach Options

### Option A: Fix slug + flip everything
Fix `create_authenticated_context` to use unique names, then flip all non-rate-limiter files to async: true. Simple, high impact.

### Option B: Fix slug + concurrency groups
Same slug fix, but use concurrency groups instead of full async for DataCase/ConnCase files. More cautious but adds complexity.

### Option C: Fix slug + rate limiter + flip everything
Fix both blockers, flip all 50 files. Maximum impact but overlaps with T-035-02 scope.

## Rate Limiter Fix Scope
The `clear_rate_limits` function is used by 5 ConnCase files. Two options:
1. **Process-local rate limiter** (T-035-02 scope) — change ETS keys to include PID
2. **Remove clear_rate_limits calls** — if tests don't actually exercise rate limiting, they don't need the cleanup
3. **Scoped clear** — clear only entries matching a test-specific key pattern

Need to check: do these files actually test rate limiting, or just clear it defensively?
