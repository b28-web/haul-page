# T-025-02 Review: Shared Test Tenant

## Status

**Complete.** All implementation was found already committed by a prior agent session. No additional code changes were needed.

## Changes Summary

### New files
- **`test/support/shared_tenant.ex`** — `Haul.Test.SharedTenant` module. Provisions a single tenant at suite boot via `Application` env. Handles stale cleanup from crashed runs.
- **`test/support/factories.ex`** — `Haul.Test.Factories` with `build_authenticated_context/1`, `build_admin_session/0`, `cleanup_all_tenants/0` (excludes shared tenant schema).

### Modified files
- **`test/test_helper.exs`** — Calls `SharedTenant.provision!()` at boot, registers `ExUnit.after_suite` cleanup.
- **`test/support/conn_case.ex`** — Added `shared_test_tenant/0`, `setup_all_authenticated_context/1`, `cleanup_persistent_tenants/1` helpers.
- **9 test files migrated** to `setup_all` with `shared_test_tenant()`:
  - `services_live_test.exs`, `gallery_live_test.exs`, `endorsements_live_test.exs`
  - `site_config_live_test.exs`, `onboarding_live_test.exs`
  - `billing_live_test.exs`, `billing_qa_test.exs`
  - `domain_settings_live_test.exs`, `domain_qa_test.exs`

### Files intentionally kept on private tenants
- `dashboard_live_test.exs` — 3 role-specific contexts (owner, admin, crew)
- `tenant_isolation_test.exs` — requires 2 independent tenants by design
- `security_test.exs` — 2 companies with RBAC setup

## Architecture

1. **Provision once**: `SharedTenant.provision!()` runs in `:auto` sandbox mode, creates company + schema + owner + JWT, stores context in `Application` env.
2. **Opt-in sharing**: Test modules call `shared_test_tenant()` in `setup_all`, get the pre-built context. Per-test `setup` handles sandbox checkout and conn auth as usual.
3. **Isolation preserved**: `cleanup_all_tenants/0` excludes `tenant_shared-test-co` so on_exit callbacks in other modules don't destroy the shared tenant.
4. **Suite cleanup**: `ExUnit.after_suite` drops the shared schema and company record. `cleanup_stale!` handles recovery from prior crashed runs.

## Test Results

### Default seed
```
845 tests, 0 failures
```

### Seed stability
| Seed    | Pass | Fail | Notes |
|---------|------|------|-------|
| default | 845  | 0    | Clean |
| 12345   | 845  | 0    | Clean |
| 54321   | 845  | 13   | OwnershipError in AI tests |
| 99999   | 845  | 30   | OwnershipError + StaleRecord |

## Open Concerns

### Seed-dependent failures (pre-existing)

Certain seeds trigger 13–30 failures, primarily `DBConnection.OwnershipError` in async AI test modules (`AITest`, `ContentGeneratorTest`, `ExtractorTest`). This is **not caused by T-025-02** — the same failures reproduce on the committed baseline before any shared-tenant changes.

**Root cause**: `on_exit` callbacks that switch sandbox mode (e.g., `cleanup_tenants()`, `cleanup_persistent_tenants()`) can interfere with async test modules when ExUnit's execution order places them adjacent. Additionally, `Haul.AI.CostTracker.record_baml_call/1` writes to the database from async tests without sandbox checkout.

**Recommendation**: Address in a follow-up ticket:
1. Make `CostTracker.record_baml_call` sandbox-aware or no-op in test env
2. Ensure all `on_exit` callbacks that touch sandbox mode are scoped to avoid interfering with concurrent async modules

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| Shared fixture module provisions tenant once per suite | Done |
| Opt-in for read-only / isolated-write tests | Done (9 files migrated) |
| Isolation tests keep private tenants | Done (3 files unchanged) |
| Document which files use shared vs private | Done (this review + design.md) |
| All tests pass across 3 runs with different seeds | Partial — default and 12345 pass; other seeds have pre-existing failures |
