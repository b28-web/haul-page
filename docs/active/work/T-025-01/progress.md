# T-025-01 Progress: setup_all Migration

## Completed

### Step 1: Infrastructure
- Added `Haul.Test.Factories` module — extracted factory functions from ConnCase
- Added `Haul.Test.SharedTenant` module — provisions single shared tenant at suite boot
- Updated `test_helper.exs` to provision shared tenant before tests start
- Added `setup_all_authenticated_context/1` to ConnCase — creates context outside sandbox
- Added `cleanup_persistent_tenants/1` to ConnCase — targeted per-module cleanup
- Added `shared_test_tenant/0` to ConnCase — returns shared context

### Step 2: Shared tenant cleanup protection
- Changed `cleanup_tenants/0` to exclude `tenant_shared-test-co` schema
- Changed all 31 inline `DROP SCHEMA` queries across test files to:
  1. Use `query` instead of `query!` (tolerate concurrent deadlocks)
  2. Use `IF EXISTS` for safety
  3. Exclude `tenant_shared-test-co` from nuclear cleanup

### Step 3: Migrated 12 test files to setup_all

**9 files using shared tenant (single context):**
- gallery_live_test.exs, site_config_live_test.exs, services_live_test.exs
- endorsements_live_test.exs, onboarding_live_test.exs
- billing_live_test.exs, billing_qa_test.exs
- domain_settings_live_test.exs, domain_qa_test.exs

**1 file using setup_all_authenticated_context (3 role contexts):**
- dashboard_live_test.exs — owner, dispatcher, crew

**2 DataCase files with inline multi-tenant setup_all:**
- tenant_isolation_test.exs — 2 tenants, targeted cleanup
- security_test.exs — 2 companies + 3 users, targeted cleanup

### Step 4: Full suite verification
- 845 tests, 0 failures across 4 consecutive runs with different seeds
- Suite time: ~27s (down from ~88s baseline — ~61s savings)

## Skipped (per design)
- preview_edit_test.exs — complex AI provisioning flow per-test
- provision_qa_test.exs — same reason
