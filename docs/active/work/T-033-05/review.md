# T-033-05 Review: async-unlock

## Summary

Flipped 11 test files from `async: false` to `async: true` and fixed the root cause of 71 pre-existing test failures (operator company slug collisions). Combined with prior tickets (T-033-02/03/04) that already flipped ~38 files, the suite is now 96 async / 3 sync.

**Wall-clock time: 77.3s → 8.5–19s** (varies by run; target was ≤60s, actual is ~12s average).

## Test Results

```
mix test --seed 0     → 898 tests, 0 failures (1 excluded), 9.3s
mix test --seed 12345 → 898 tests, 0 failures (1 excluded), 8.3s
mix test --seed 99999 → 898 tests, 0 failures (1 excluded), 8.5s
```

Timing breakdown (representative run):
- Async: 10.3s (96 files, ~880 tests)
- Sync: 0.7s (3 files, ~18 tests)
- Total: 11.0s

## Files Changed

### Infrastructure (3 files)
| File | Change |
|------|--------|
| `test/support/factories.ex` | Added `ensure_operator_tenant!/0` and `operator_context/0` |
| `test/test_helper.exs` | Added `ensure_operator_tenant!/0` call + `DELETE FROM admin_users` cleanup |
| `test/support/conn_case.ex` | Changed `create_operator_context` from destructive create to lookup |

### Flipped to async: true (11 files)
| File | Key change |
|------|------------|
| `test/haul_web/controllers/page_controller_test.exs` | Removed setup_all, simplified to setup + operator lookup |
| `test/haul_web/controllers/webhook_controller_test.exs` | Removed operator company creation + global cleanup |
| `test/haul_web/smoke_test.exs` | Removed Seeder.seed! (now in test_helper) + global cleanup |
| `test/haul_web/live/booking_live_test.exs` | Removed global cleanup |
| `test/haul_web/live/booking_live_upload_test.exs` | Removed global cleanup |
| `test/haul_web/live/booking_live_autocomplete_test.exs` | Removed global cleanup |
| `test/haul_web/live/scan_live_test.exs` | Removed Seeder.seed! + global cleanup |
| `test/haul_web/live/payment_live_test.exs` | Removed global cleanup |
| `test/haul_web/live/tenant_hook_test.exs` | Removed global cleanup |
| `test/haul/accounts/company_test.exs` | Removed global cleanup |
| `test/mix/tasks/haul/onboard_test.exs` | Removed global cleanup |

### Bug fix (1 file)
| File | Change |
|------|--------|
| `test/haul_web/live/app/billing_live_test.exs` | `Ash.read_one!(Company)` → `Ash.get!(Company, id)` (multiple companies visible) |

## Files Remaining async: false (3 files)

| File | Reason | Impact |
|------|--------|--------|
| `integration_test.exs` | Live BAML test, excluded by default (`@moduletag :baml_live`) | 0s — never runs |
| `onboarding_live_test.exs` | `setup_all` + `Application.put_env(:haul, :operator)` in one describe block | ~0.3s |
| `accounts_live_test.exs` | `setup_all` with hardcoded company names visible to all connections | ~0.4s |

Combined sync time: <1s. Not worth the complexity of converting.

## Root Cause Fix: Operator Company Deduplication

The biggest win was fixing the **operator company slug collision**. The problem:
1. `page_controller_test`'s `setup_all` created a company with the operator slug (committed outside sandbox)
2. 9+ other test files tried to create the same slug in their `setup` blocks
3. The unique constraint fired, causing 71 failures with deterministic seeds

**Fix:** Create the operator company ONCE in `test_helper.exs` via `ensure_operator_tenant!/0`. All tests now look up the pre-created data via `operator_context()`. No per-test DDL, no slug collisions, safe for concurrent access.

## Timing Comparison

| Metric | Before (T-033-04) | After | Improvement |
|--------|-------------------|-------|-------------|
| Wall-clock | 77.3s | ~12s | **6.4× faster** |
| Async time | unknown | 10.3s | — |
| Sync time | unknown | 0.7s | — |
| Async files | ~50 | 96 | +46 files |
| Sync files | ~50 | 3 | −47 files |
| Failures (seed 0) | 71 | 0 | Fixed |

## Test Coverage

No test coverage gaps. All existing tests pass. No tests were removed or weakened.

## Open Concerns

1. **56 "shared mode" warnings** from `DBConnection.OwnershipError` — pre-existing, caused by async unit tests (ExUnit.Case) that don't use DataCase but call modules that happen to touch the DB through Ash. Not related to this ticket; could be addressed by adding `@tag :requires_db` or converting those tests to DataCase.

2. **Schema accumulation** — since we removed per-test `on_exit` cleanup, tenant schemas from `build_authenticated_context` calls accumulate during the test run. `cleanup_all_tenants()` in test_helper handles cleanup at the start of the next run. This is acceptable.

3. **accounts_live_test and onboarding_live_test** could theoretically be converted to async by removing their `setup_all` patterns, but the combined sync time is <1s so the ROI is negligible.

4. **Stale admin_users from setup_all :auto mode** — `accounts_live_test` commits admin_users permanently via `:auto` sandbox mode. Fixed by cleaning admin_users at suite start and in the module's own setup_all.
