# T-027-02 Plan: Resource Factories

## Step 1: Add resource factories to Haul.Test.Factories

- Add aliases for content/operations resources
- Implement 6 `build_*` functions with defaults and `authorize?: false`
- Update `@moduledoc`
- **Verify:** `mix compile --warnings-as-errors` passes

## Step 2: Add Factories import to ConnCase

- Add `import Haul.Test.Factories` to ConnCase `using` block
- **Verify:** existing tests still pass (`mix test test/haul_web/live/app/services_live_test.exs`)

## Step 3: Migrate content domain tests (5 files)

Migrate one at a time, running targeted tests after each:

- `test/haul/content/service_test.exs` → `build_service`
- `test/haul/content/gallery_item_test.exs` → `build_gallery_item`
- `test/haul/content/endorsement_test.exs` → `build_endorsement`
- `test/haul/content/page_test.exs` → `build_page`
- `test/haul/content/site_config_test.exs` → `build_site_config`

**Verify after each:** `mix test test/haul/content/<file>`

## Step 4: Migrate job_test

- `test/haul/operations/job_test.exs` → `build_job`
- **Verify:** `mix test test/haul/operations/job_test.exs`

## Step 5: Migrate LiveView tests (3 files)

- `test/haul_web/live/app/services_live_test.exs` — remove `create_service/2`, use `build_service`
- `test/haul_web/live/app/gallery_live_test.exs` — remove `create_item/2`, use `build_gallery_item`
- `test/haul_web/live/app/endorsements_live_test.exs` — remove `create_endorsement/2`, use `build_endorsement`

**Verify after each:** `mix test test/haul_web/live/app/<file>`

## Step 6: Full suite verification

- `mix test` — all 845+ tests pass
- Note any regressions

## Testing Strategy

- No new test file needed — the factories are tested implicitly by all migrated tests
- Each migration verifies the factory works with real Ash actions and validations
- Full suite run catches any missed imports or broken references
