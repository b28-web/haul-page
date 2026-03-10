# T-033-05 Progress: async-unlock

## Completed

### Step 1: Fix operator company slug collisions (root cause)
- **Problem:** `page_controller_test`'s `setup_all` persisted an operator company. Other test files tried to create the same slug, causing unique constraint violations (71 pre-existing failures with seed 0).
- **Fix:** Added `ensure_operator_tenant!/0` to `test/support/factories.ex`. Creates operator company + tenant + seeds content once in `test_helper.exs`. Changed `create_operator_context` in `ConnCase` to look up pre-created data instead of destructively recreating it.
- **Files changed:** `test/support/factories.ex`, `test/test_helper.exs`, `test/support/conn_case.ex`

### Step 2: Remove global cleanup from operator-slug test files
All files that used `on_exit(fn -> cleanup_tenants() end)` (drops ALL schemas) were updated to remove the cleanup. The operator tenant persists for the entire test run; `cleanup_all_tenants()` in test_helper handles cleanup at the next run.

### Step 3: Flip 11 files to async: true
1. `test/haul_web/controllers/page_controller_test.exs` — removed setup_all, simplified to setup
2. `test/haul_web/controllers/webhook_controller_test.exs` — removed operator company creation
3. `test/haul_web/smoke_test.exs` — removed Seeder.seed! (now done in test_helper)
4. `test/haul_web/live/booking_live_test.exs`
5. `test/haul_web/live/booking_live_upload_test.exs`
6. `test/haul_web/live/booking_live_autocomplete_test.exs`
7. `test/haul_web/live/scan_live_test.exs` — removed Seeder.seed!
8. `test/haul_web/live/payment_live_test.exs`
9. `test/haul_web/live/tenant_hook_test.exs`
10. `test/haul/accounts/company_test.exs`
11. `test/mix/tasks/haul/onboard_test.exs`

### Step 4: Fix billing_live_test assertion
- `billing_live_test:84` did `Ash.read_one!(Company)` which failed with multiple companies (operator + test company). Changed to `Ash.get!(Company, ctx.company.id)`.

### Step 5: Fix stale admin_users from setup_all :auto mode
- **Problem:** `accounts_live_test` uses `setup_all` with `:auto` sandbox mode, committing admin_users permanently. On subsequent runs, `System.unique_integer` can produce values that collide with stale admin emails.
- **Fix:** Added `DELETE FROM admin_users` to `test_helper.exs` suite-start cleanup and to `accounts_live_test` setup_all cleanup block.

### Step 6: Verification (3 seeds, 0 failures each)
- `mix test --seed 0`     → 898 tests, 0 failures, 9.3s
- `mix test --seed 12345` → 898 tests, 0 failures, 8.3s
- `mix test --seed 99999` → 898 tests, 0 failures, 8.5s

## Files remaining async: false (4 files, documented)
1. `accounts_live_test.exs` — setup_all with hardcoded companies visible to all tests
2. `onboarding_live_test.exs` — setup_all + Application.put_env(:haul, :operator) in one describe block
3. `integration_test.exs` — live BAML test, excluded by default
4. *(none of the above have practical blocking impact — they run in <1s total)*

## Deviations from plan
- Plan expected 42+ files to flip; actual: only 12 remained (prior tickets T-033-02/03/04 already flipped ~38 files)
- Plan did not anticipate the operator company slug collision as a root cause of 71 pre-existing failures
- Rate limiter was already fixed by T-035-02 (process-local keys) — no changes needed here
- `clear_rate_limits` debug logging was simplified by a linter hook
