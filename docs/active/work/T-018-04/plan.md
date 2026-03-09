# T-018-04 Plan: Extraction Tests

## Step 1: Add `valid_email?/1` to Extractor

Add a simple email format check function to `lib/haul/ai/extractor.ex`:
- Pattern: `~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/`
- Returns `false` for nil
- Pure function, no side effects

Verify: `mix compile --no-deps-check`

## Step 2: Add `to_differentiators_content/1` to ProfileMapper

Add to `lib/haul/ai/profile_mapper.ex`:
- Takes `%OperatorProfile{}`, returns markdown bullet list or nil if empty
- Format: `"- Item 1\n- Item 2\n- Item 3"`
- Returns nil for empty list

Verify: `mix compile --no-deps-check`

## Step 3: Add missing extractor tests

Add to `test/haul/ai/extractor_test.exs`:
1. Pure garbage input test — sandbox returns all-nil profile, assert no crash
2. Phone format preservation test — sandbox returns specific format, assert passthrough
3. `valid_email?/1` tests — valid formats, invalid formats, nil

Verify: `mix test test/haul/ai/extractor_test.exs`

## Step 4: Add missing profile_mapper tests

Add to `test/haul/ai/profile_mapper_test.exs`:
1. `to_differentiators_content/1` — with items → markdown bullets
2. `to_differentiators_content/1` — empty list → nil
3. `to_differentiators_content/1` — profile with no differentiators

Verify: `mix test test/haul/ai/profile_mapper_test.exs`

## Step 5: Create integration test file

Create `test/haul/ai/integration_test.exs`:
- `@moduletag :baml_live`
- Test sends real transcript to `Haul.AI.Baml.call_function/2`
- Verify result is `{:ok, map}` with expected keys
- Log latency

## Step 6: Configure ExUnit exclusion

Update `test/test_helper.exs` to exclude `:baml_live` tag by default.

Verify: `mix test test/haul/ai/` (should skip integration tests)

## Step 7: Run full test suite

`mix test` — all tests pass, integration tests excluded.

## Commit strategy

Single commit: "T-018-04: comprehensive extraction pipeline tests"
