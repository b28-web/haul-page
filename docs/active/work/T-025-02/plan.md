# T-025-02 Plan: Shared Test Tenant

## Step 1: Create Haul.Test.SharedTenant module

Create `test/support/shared_tenant.ex` with `provision!/0`, `get!/0`, `cleanup!/0`.

Verify: Module compiles (`mix compile --warnings-as-errors`).

## Step 2: Wire into test_helper.exs

Add `SharedTenant.provision!()` call and `ExUnit.after_suite` cleanup registration.

Verify: `mix test test/haul_web/live/app/services_live_test.exs` still passes (no behavioral change yet, but shared tenant is now created at boot).

## Step 3: Add shared_test_tenant/0 helper to ConnCase

Add the helper function and import it via the `using` block.

Verify: Compile check.

## Step 4: Migrate 9 test files to shared tenant

Replace `setup_all` blocks in all 9 files. Each file's `setup_all` becomes `%{ctx: shared_test_tenant()}` with no `on_exit` cleanup.

Verify after each file:
```bash
mix test test/haul_web/live/app/<file>.exs
```

## Step 5: Full suite verification

Run `mix test` and verify all 845 tests pass.
Run with 3 different seeds to check for ordering issues.

## Testing Strategy

- **Per-step:** Targeted test runs after each file migration.
- **Final:** Full suite `mix test` with multiple seeds.
- **No new tests needed:** This is a test infrastructure optimization. Existing tests ARE the verification — if they pass with the shared tenant, the migration is correct.

## Risk Mitigation

- **If a test fails after migration:** The likely cause is the test relying on a fresh company record (e.g., expecting default company name). Fix by making the test's assertion tenant-agnostic or by creating per-test data inside sandbox.
- **Stale state from prior run:** `provision!` cleans up before creating, and `after_suite` cleans up after. Double protection.
- **Compile order:** `test/support/` is compiled before test files (configured in `mix.exs` `elixirc_paths`). `shared_tenant.ex` will be available.
