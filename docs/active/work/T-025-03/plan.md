# T-025-03 Plan: Timing Verification

## Step 1: Rename build_job → build_booking_job
Fix compilation conflict with `Oban.Testing.build_job/2`.
- Update `test/support/factories.ex`
- Update all callers (send_booking_email_test, send_booking_sms_test, tenant_isolation_test)

## Step 2: Fix sandbox mode race condition
Convert tests that use `setup_all_authenticated_context()` to per-test `setup`:
- `security_test.exs` — per-test tenant creation with `cleanup_all_tenants()`
- `tenant_isolation_test.exs` — same
- `dashboard_live_test.exs` — per-test `create_authenticated_context()`

## Step 3: Fix StaleRecord in billing tests
Move billing tests to private tenant with per-test company reload:
- `billing_live_test.exs` — `setup_all_authenticated_context()` + per-test `Ash.get!`
- `billing_qa_test.exs` — same pattern

## Step 4: Fix cleanup_persistent_tenants
Use raw Postgrex connection instead of switching `Sandbox.mode(:auto)`.

## Step 5: Verify 0 failures
Run `mix test` — expect 845 tests, 0 failures.

## Step 6: Timing telemetry run
Run `HAUL_TEST_TIMING=1 mix test` and capture report.

## Step 7: Multi-seed stability check
Run `mix test --seed <N>` with multiple seeds. Record pass/fail.

## Step 8: Document results
Write progress.md and review.md with before/after comparison.

## Testing Strategy
- Full suite after each step (Steps 1-4)
- Timing run in Step 6
- Multiple seed runs in Step 7
