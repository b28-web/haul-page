# T-025-03 Design: Timing Verification

## Problem

Multiple issues causing test failures depending on seed order:

1. **Sandbox mode race condition (critical)**: `setup_all_authenticated_context()` calls
   `Sandbox.mode(Haul.Repo, :auto)` globally, breaking concurrent non-async modules'
   sandbox connections. Causes JWT verification failures → login redirects.

2. **`build_job/2` name conflict**: `Factories.build_job/2` conflicts with
   `Oban.Testing.build_job/2` when both imported via DataCase.

3. **BillingLiveTest StaleRecord**: Shared company mutated by `set_company_plan()`;
   other tests hold stale copies.

4. **CostTracker OwnershipError (pre-existing)**: `CostTracker.record_baml_call/1`
   writes to DB from async tests without sandbox checkout. Warning only.

## Options

### Option A: Convert setup_all → per-test setup
Move tenant creation into `setup` blocks. Slower but eliminates sandbox mode switching.

**Pro:** Completely eliminates race condition. Each test owns its sandbox.
**Con:** More DB work per test; slower for files that create 3+ tenants.

### Option B: Raw Postgrex for setup_all cleanup
Keep `setup_all` pattern but use raw Postgrex connections for cleanup instead
of switching sandbox mode globally.

**Pro:** Keeps performance of shared setup. Targeted fix.
**Con:** Doesn't fix the setup phase (still needs `:auto` to create tenants).

### Option C: Hybrid — private tenants for mutating tests, shared for read-only
Tests that mutate company state get their own tenant via `setup_all_authenticated_context`.
Read-only tests use `shared_test_tenant()`.

**Pro:** Optimal performance. Mutation-safe.
**Con:** More complex; still has sandbox mode issue during setup_all.

## Decision: Hybrid (Option A for problem tests + Option B for cleanup)

1. Convert SecurityTest, TenantIsolationTest, DashboardLiveTest to per-test `setup`
   (they used `setup_all_authenticated_context` which switches sandbox mode)
2. Move BillingLiveTest/BillingQaTest to private tenants with per-test company reload
3. Rename `build_job` → `build_booking_job` to resolve Oban conflict
4. Change `cleanup_persistent_tenants` to use raw Postgrex (no sandbox mode switch)

## Verification Plan
1. Apply all fixes
2. Run `mix test` — expect 0 failures
3. Run `HAUL_TEST_TIMING=1 mix test` — capture timing report
4. Run multiple seeds — verify stability
5. Document before/after comparison
