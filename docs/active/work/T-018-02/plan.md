# T-018-02 Plan: Profile Types

## Step 1: Schema migrations + resource updates

1a. Create tenant migration: add `owner_name` (string, nullable) to `site_configs`
1b. Create tenant migration: add `category` (string, nullable) to `services`
1c. Add `owner_name` attribute to SiteConfig resource, update `:create_default` and `:edit` actions to accept it
1d. Add `category` attribute to Service resource (atom, one_of enum), update `:add` and `:edit` actions to accept it

**Verify:** `mix ash.codegen` succeeds, `mix test` passes (existing tests unaffected by additive changes)

## Step 2: BAML type definitions

2a. Add OperatorProfile, ServiceOffering, and ServiceCategory types to `baml/main.baml`
    - Types only, no function (extraction function is T-018-03's job)

**Verify:** BAML syntax is valid (no runtime compilation errors)

## Step 3: OperatorProfile Elixir struct

3a. Create `lib/haul/ai/operator_profile.ex`:
    - `defstruct` with all fields, `@type t()`
    - Nested `ServiceOffering` module with `defstruct`
    - `from_baml/1` converts string-keyed map → struct
    - `@service_categories` for category validation

3b. Create `test/haul/ai/operator_profile_test.exs`:
    - Test full map parsing
    - Test partial map (missing optionals → nil)
    - Test invalid category → `:other` fallback

**Verify:** `mix test test/haul/ai/operator_profile_test.exs` passes

## Step 4: ProfileMapper

4a. Create `lib/haul/ai/profile_mapper.ex`:
    - `to_company_attrs/1`
    - `to_site_config_attrs/1`
    - `to_service_attrs_list/1`
    - `missing_fields/1`

4b. Create `test/haul/ai/profile_mapper_test.exs`:
    - Valid profile → correct attrs for each resource
    - Field name mapping (ServiceOffering.name → Service.title)
    - Partial profile → missing_fields returns [:phone, :email] etc.
    - Empty services list → empty list
    - Icon assignment based on category

**Verify:** `mix test test/haul/ai/profile_mapper_test.exs` passes

## Step 5: Sandbox fixture

5a. Add `"ExtractOperatorProfile"` clause to `Haul.AI.Sandbox.call_function/2`
    - Return realistic fixture with all fields populated

**Verify:** `mix test test/haul/ai_test.exs` still passes

## Step 6: Full test suite

**Verify:** `mix test` — all tests pass, no regressions

## Testing Strategy

- **Unit tests** for OperatorProfile.from_baml/1 — struct construction, optional handling, enum parsing
- **Unit tests** for ProfileMapper — pure function testing, no DB needed
- **Existing tests** verify no regressions from schema changes (additive columns are nullable)
- **No integration tests needed** — ProfileMapper is pure data transformation; integration with Ash actions tested in T-018-03/T-018-04
