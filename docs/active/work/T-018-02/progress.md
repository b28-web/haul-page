# T-018-02 Progress: Profile Types

## Completed

### Step 1: Schema migrations + resource updates ✅
- Created tenant migration: `add_owner_name_to_site_configs` (uses up/down with prefix())
- Created tenant migration: `add_category_to_services` (uses up/down with prefix())
- Added `owner_name` attribute to SiteConfig, updated `:create_default` and `:edit` actions
- Added `category` atom attribute to Service with `one_of` constraint, updated `:add` and `:edit` actions

### Step 2: BAML type definitions ✅
- Added `OperatorProfile`, `ServiceOffering`, and `ServiceCategory` types to `baml/main.baml`
- Types only — no extraction function (that's T-018-03)

### Step 3: OperatorProfile Elixir struct ✅
- Created `lib/haul/ai/operator_profile.ex` with `from_baml/1`
- Nested `ServiceOffering` module with category enum parsing
- 6 tests passing in `operator_profile_test.exs`

### Step 4: ProfileMapper ✅
- Created `lib/haul/ai/profile_mapper.ex` with 4 public functions
- Maps profile fields to Company, SiteConfig, and Service attrs
- Auto-assigns icons based on category
- `missing_fields/1` for partial profile validation
- 8 tests passing in `profile_mapper_test.exs`

### Step 5: Sandbox fixture ✅
- Added `"ExtractOperatorProfile"` clause with realistic fixture data
- Existing AI tests still pass

### Step 6: Full test suite ✅
- 520 tests, 0 failures (up from 258 baseline — other tickets added tests too)

## Deviations from plan
- Tenant migrations required `up/down` with `prefix: prefix()` instead of `change/0` — learned from existing migration pattern in `add_endorsement_sort_order.exs`
- Nested module reference needed `__MODULE__.ServiceOffering` instead of bare `ServiceOffering`
