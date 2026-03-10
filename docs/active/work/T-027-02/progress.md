# T-027-02 Progress: Resource Factories

## Completed

### Step 1: Add resource factories to Haul.Test.Factories ✓
- Added aliases for content/operations resources
- Implemented 6 `build_*` functions: `build_service`, `build_gallery_item`, `build_endorsement`, `build_site_config`, `build_page`, `build_job`
- Updated `@moduledoc` with resource factory documentation
- All use `authorize?: false` and `Ash.create!`
- Compilation clean

### Step 2: Add Factories import to ConnCase ✓
- Added `import Haul.Test.Factories` to ConnCase `using` block
- LiveView tests now have direct access to factory functions

### Step 3: Migrate content domain tests (5 files) ✓
- `service_test.exs` — simplified setup (build_company/provision_tenant/cleanup_all_tenants), replaced creation-as-setup in edit/destroy/sort tests
- `gallery_item_test.exs` — simplified setup, replaced creation-as-setup in edit test
- `endorsement_test.exs` — simplified setup
- `page_test.exs` — simplified setup, replaced creation-as-setup in edit/publish/unpublish/unique-slug tests
- `site_config_test.exs` — simplified setup, replaced creation-as-setup in edit/read tests

### Step 4: Migrate job_test ✓
- Simplified setup block

### Step 5: Migrate LiveView tests (3 files) ✓
- `services_live_test.exs` — removed `create_service/2` helper, replaced with `build_service`
- `gallery_live_test.exs` — removed `create_item/2` helper, replaced with `build_gallery_item`
- `endorsements_live_test.exs` — removed `create_endorsement/2` helper, replaced with `build_endorsement`

### Step 6: Full suite verification ✓
- 845 tests, 0 failures

## Deviations from plan

- Kept `@valid_attrs` module attributes and inline `Ash.Changeset.for_create` in tests that directly test the creation action behavior (validation errors, required fields, etc.) — these need to exercise the action directly to be meaningful tests
- Only replaced creation calls that serve as setup for testing other functionality (edit, destroy, read, publish, etc.)
