# T-025-01 Review: setup_all Migration

## Summary

Migrated 12 test files from per-test `create_authenticated_context()` to once-per-module `setup_all`, eliminating redundant Postgres schema provisioning (~150-200ms each). Suite wall time dropped from ~88s to ~27s — a ~61s improvement (69% reduction).

## Full Suite Result

```
845 tests, 0 failures (1 excluded)
Verified across 4 consecutive runs with seeds: default, 12345, 99999, 42424
Suite time: ~27s (baseline: ~88s)
```

## Files Changed

### New files
- `test/support/factories.ex` — Extracted factory functions from ConnCase into standalone module
- `test/support/shared_tenant.ex` — Provisions single shared tenant once per suite, cleaned up via `ExUnit.after_suite/1`

### Test infrastructure
- `test/support/conn_case.ex` — Delegates to Factories; added `shared_test_tenant/0`, `setup_all_authenticated_context/1`, `cleanup_persistent_tenants/1`
- `test/test_helper.exs` — Added `SharedTenant.provision!()` and after_suite cleanup

### Test files migrated (12)
| File | Tests | Change |
|------|-------|--------|
| dashboard_live_test.exs | 7 | 3 role contexts via `setup_all_authenticated_context` |
| gallery_live_test.exs | 11 | `shared_test_tenant()` |
| site_config_live_test.exs | 8 | `shared_test_tenant()` |
| services_live_test.exs | 11 | `shared_test_tenant()` |
| endorsements_live_test.exs | 11 | `shared_test_tenant()` |
| onboarding_live_test.exs | 14 | `shared_test_tenant()`, seed per-test |
| billing_live_test.exs | 14 | `shared_test_tenant()` |
| billing_qa_test.exs | 16 | `shared_test_tenant()` |
| domain_settings_live_test.exs | 16 | `shared_test_tenant()` |
| domain_qa_test.exs | 14 | `shared_test_tenant()` |
| tenant_isolation_test.exs | 10 | 2 inline contexts, targeted cleanup |
| security_test.exs | 11 | 2 inline contexts, targeted cleanup |

### Cleanup safety (31 test files)
All files with inline `DROP SCHEMA` cleanup updated to:
1. Use `query` instead of `query!` (tolerate concurrent deadlocks)
2. Use `DROP SCHEMA IF EXISTS` for safety
3. Exclude `tenant_shared-test-co` from nuclear cleanup

### Files NOT modified (2 skipped)
- `test/haul_web/live/preview_edit_test.exs` — complex AI provisioning flow
- `test/haul_web/live/provision_qa_test.exs` — same reason

## Architecture

**Shared tenant pattern (9 files):** Single tenant provisioned at suite boot via `SharedTenant.provision!` in test_helper.exs. Admin LiveView tests that need a standard owner context share this tenant. Per-test sandbox still isolates data mutations.

**Per-module setup_all (3 files):** Dashboard (3 role contexts) and DataCase files (tenant_isolation, security) use `setup_all_authenticated_context` or inline multi-tenant setup.

**Targeted cleanup:** Each setup_all module cleans up only its own schemas via `cleanup_persistent_tenants([ctx])`. Nuclear cleanup in 31 other files excludes the shared tenant.

## Test Coverage

- All 845 tests pass unchanged across 4 seeds
- No new tests added (performance optimization only)
- Cross-cutting tests (tenant_isolation, security) verified with unique company names

## Open Concerns

1. **2 files skipped:** preview_edit_test.exs and provision_qa_test.exs (~6.3s potential). Complex AI flows make shared-state migration risky.

2. **Hardcoded exclusion:** 31 files have `AND schema_name != 'tenant_shared-test-co'` inline. If the shared tenant name changes, all need updating. Future: centralize into a single helper.

3. **Sandbox mode dependency:** `setup_all_authenticated_context` uses global `Sandbox.mode(:auto)` for DDL. Safe because `async: false` tests run after `async: true`, but it's a subtle ordering requirement.
