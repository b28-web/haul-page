# T-033-02 Structure: Extract Pure Logic

## Files created

### `test/haul/onboarding_unit_test.exs`
```
defmodule Haul.OnboardingUnitTest do
  use ExUnit.Case, async: true

  describe "derive_slug/1"
    - 4 tests (copied from onboarding_test.exs)

  describe "site_url/1"
    - 1 test (copied from onboarding_test.exs)
end
```

### `test/haul/ai/cost_tracker_unit_test.exs`
```
defmodule Haul.AI.CostTrackerUnitTest do
  use ExUnit.Case, async: true

  describe "estimate_tokens/1"
    - 3 tests (moved from cost_tracker_test.exs)

  describe "estimate_cost/3"
    - 3 tests (moved from cost_tracker_test.exs)

  describe "model_for_function/1"
    - 3 tests (moved from cost_tracker_test.exs)

  describe "pricing/0"
    - 1 test (moved from cost_tracker_test.exs)
end
```

## Files modified

### `test/haul/onboarding_test.exs`
- Remove `describe "derive_slug/1"` block (lines 127-143)
- Remove `describe "site_url/1"` block (lines 145-151)
- Keep all `describe "run/1"` tests (lines 35-125) — these need DB

### `test/haul/ai/cost_tracker_test.exs`
- Remove `describe "estimate_tokens/1"` block (lines 13-29)
- Remove `describe "estimate_cost/3"` block (lines 31-51)
- Remove `describe "model_for_function/1"` block (lines 53-75)
- Remove `describe "pricing/0"` block (lines 278-287)
- Keep: record_call, record_baml_call, session_total, daily_total, monthly_total, average_session_cost, threshold alerts — all need DB

### `test/haul/content/seeder_test.exs`
- Remove `describe "parse_frontmatter!/1"` block (lines 144-169)
- Keep all seed!/1 and seed!/2 tests — these need DB

## Files unchanged

- All production modules (`lib/`) — no code changes
- `test/haul/content/markdown_test.exs` — already has full unit coverage of parse_frontmatter!

## Ordering

1. Create new unit test files first (additive, safe)
2. Remove describe blocks from DataCase files
3. Run `mix test --stale` to verify
