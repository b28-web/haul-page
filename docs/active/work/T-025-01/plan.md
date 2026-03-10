# T-025-01 Plan: setup_all Migration

## Step 1: Add ConnCase Helper

**File:** `test/support/conn_case.ex`
**Change:** Add `setup_all_authenticated_context/1` function
**Test:** Compile check — no tests to run yet
**Commit:** "Add setup_all_authenticated_context helper to ConnCase"

## Step 2: Migrate dashboard_live_test.exs (simplest — read-only)

**File:** `test/haul_web/live/app/dashboard_live_test.exs`
**Change:**
- Add setup_all with 3 role contexts (owner, dispatcher, crew)
- Per-test setup: sandbox + conn from shared context
- Remove per-describe context creation
**Test:** `mix test test/haul_web/live/app/dashboard_live_test.exs --seed 0 && mix test test/haul_web/live/app/dashboard_live_test.exs --seed 12345 && mix test test/haul_web/live/app/dashboard_live_test.exs --seed 99999`
**Commit:** "Migrate dashboard_live_test to setup_all"

## Step 3: Migrate gallery_live_test.exs

**File:** `test/haul_web/live/app/gallery_live_test.exs`
**Change:** setup_all for context, per-test setup for sandbox + conn
**Test:** Run 3x with different seeds
**Commit:** "Migrate gallery_live_test to setup_all"

## Step 4: Migrate site_config_live_test.exs

Same pattern as gallery. Run 3x with different seeds.

## Step 5: Migrate services_live_test.exs

Same pattern. CRUD tests with unique names — sandbox rollback handles isolation.

## Step 6: Migrate endorsements_live_test.exs

Same pattern as services.

## Step 7: Migrate onboarding_live_test.exs

**Note:** Uses `Haul.Content.Seeder.seed!/1` in setup. Seeding must happen per-test (inside sandbox) since it creates data. Only context creation moves to setup_all.

## Step 8: Migrate billing_live_test.exs (Group C)

**Change:** Move inline `create_authenticated_context()` to setup_all. Each test receives shared ctx. Company mutations happen in sandbox, roll back per-test.

## Step 9: Migrate billing_qa_test.exs

Same pattern as billing_live.

## Step 10: Migrate domain_settings_live_test.exs

Same pattern. Inline `authenticated_conn()` calls replaced with shared conn.

## Step 11: Migrate domain_qa_test.exs

Same pattern as domain_settings.

## Step 12: Migrate tenant_isolation_test.exs (Group D)

**Change:** 2 contexts in setup_all. Tests receive both. Careful — tests assert on data created in setup, not per-test. Need to verify assertions still pass.

## Step 13: Migrate security_test.exs (Group D)

**Change:** 2 company contexts in setup_all. Role-based policy tests should work since the user/role data is fixed.

## Step 14: Full Suite Verification

Run `mix test` full suite. Verify 845 tests pass with 0 failures.
Run 2 additional times with different seeds for flakiness detection.

## Testing Strategy

- **Per-file:** 3 runs with different seeds after each migration
- **Full suite:** After all migrations complete
- **Flakiness detection:** 3 full-suite runs with random seeds
- **Success criteria:** All 845 tests pass, no new flaky tests
