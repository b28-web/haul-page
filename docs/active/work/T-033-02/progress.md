# T-033-02 Progress: Extract Pure Logic

## Completed

### Step 1: Created onboarding unit test file ✓
- `test/haul/onboarding_unit_test.exs` — 5 tests, ExUnit.Case async: true
- derive_slug/1 (4 tests) + site_url/1 (1 test)
- Passes in 0.01s

### Step 2: Created cost_tracker unit test file ✓
- `test/haul/ai/cost_tracker_unit_test.exs` — 10 tests, ExUnit.Case async: true
- estimate_tokens (3), estimate_cost (3), model_for_function (3), pricing (1)
- Passes in 0.01s

### Step 3: Removed extracted tests from DataCase files ✓
- `onboarding_test.exs`: 13 → 8 tests (removed derive_slug + site_url blocks)
- `cost_tracker_test.exs`: 24 → 14 tests (removed 4 pure-function describe blocks)
- `seeder_test.exs`: 6 → 4 tests (removed parse_frontmatter! block — covered by markdown_test.exs)

### Step 4: Verified ✓
- `mix test --stale`: 525 tests, 0 failures (70.5s)
- Per-file counts match expected values

## Remaining

- Full suite verification (`mix test`)
- Review artifact
