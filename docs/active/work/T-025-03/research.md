# T-025-03 Research: Timing Verification

## Current State

### Timing (HAUL_TEST_TIMING=1)
- **Wall clock: 35-43s** (target: <45s) — met
- Setup/compile overhead: ~500ms
- Sync files: 58 (28-35s)
- Async files: 37 (7-10s)
- Total tests: 845 (1 excluded: baml_live)

### Baseline (pre-optimization)
- T-024-02 analysis: 173s wall clock, 746 tests
- After T-024-03: 78.5s
- After T-025-01 setup_all migration: ~27-35s

### Top 10 Slowest Files
| # | File | Time | Tests |
|---|------|------|-------|
| 1 | preview_edit_test.exs | 4.3s | 13 |
| 2 | chat_qa_test.exs | 4.1s | 25 |
| 3 | provision_qa_test.exs | 3.6s | 14 |
| 4 | chat_live_test.exs | 2.8s | 22 |
| 5 | superadmin_qa_test.exs | 1.6s | 18 |
| 6 | impersonation_test.exs | 0.8s | 16 |
| 7 | proxy_qa_test.exs | 0.8s | 13 |
| 8 | cost_tracker_test.exs | 0.7s | 24 |
| 9 | edit_applier_test.exs | 0.7s | 11 |
| 10 | onboarding_qa_test.exs | 0.7s | 10 |

## Issues Found

### 1. `build_job/2` name conflict with Oban.Testing
`Factories.build_job/2` conflicts with `Oban.Testing.build_job/2` when both are imported via DataCase. Seed-dependent compilation failure.

### 2. BillingLiveTest StaleRecord
Billing tests mutate shared company via `set_company_plan()`. StaleRecord errors cascade.

### 3. Sandbox mode race condition (critical)
`setup_all_authenticated_context()` and cleanup callbacks switch `Sandbox.mode(Haul.Repo, :auto)` globally. This breaks concurrent non-async modules' sandbox connections, causing JWT verification failures (login redirects).

### 4. CostTracker OwnershipError (pre-existing)
`CostTracker.record_baml_call/1` writes to DB from async tests without sandbox checkout. Warning only.

## Key Files
- `test/support/factories.ex` — Factory functions, `cleanup_all_tenants/0`
- `test/support/shared_tenant.ex` — Suite-wide shared tenant
- `test/support/conn_case.ex` — Auth helpers, cleanup helpers
- `test/support/data_case.ex` — Sandbox setup, Factories import
- `test/support/timing_formatter.ex` — Timing telemetry
