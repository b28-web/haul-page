# T-033-02 Plan: Extract Pure Logic

## Step 1: Create onboarding unit test file

Create `test/haul/onboarding_unit_test.exs` with:
- `use ExUnit.Case, async: true`
- Copy `describe "derive_slug/1"` (4 tests) from onboarding_test.exs
- Copy `describe "site_url/1"` (1 test) from onboarding_test.exs
- Verify: `mix test test/haul/onboarding_unit_test.exs` — 5 tests, 0 failures

## Step 2: Create cost_tracker unit test file

Create `test/haul/ai/cost_tracker_unit_test.exs` with:
- `use ExUnit.Case, async: true`
- Copy `describe "estimate_tokens/1"` (3 tests)
- Copy `describe "estimate_cost/3"` (3 tests)
- Copy `describe "model_for_function/1"` (3 tests)
- Copy `describe "pricing/0"` (1 test)
- Verify: `mix test test/haul/ai/cost_tracker_unit_test.exs` — 10 tests, 0 failures

## Step 3: Remove extracted tests from DataCase files

- `onboarding_test.exs`: delete the derive_slug and site_url describe blocks
- `cost_tracker_test.exs`: delete estimate_tokens, estimate_cost, model_for_function, pricing describe blocks
- `seeder_test.exs`: delete parse_frontmatter! describe block (covered by markdown_test.exs)
- Verify: `mix test --stale` — all pass, no net test loss

## Step 4: Verify coverage accounting

Run affected test files individually to confirm test counts:
- `onboarding_test.exs`: should drop from 13 → 8 tests
- `onboarding_unit_test.exs`: 5 tests
- `cost_tracker_test.exs`: should drop from 24 → 14 tests
- `cost_tracker_unit_test.exs`: 10 tests
- `seeder_test.exs`: should drop from 6 → 4 tests
- `markdown_test.exs`: unchanged at its current count (already covers frontmatter)

## Step 5: Full suite verification

Run `mix test` and confirm 0 failures with correct total count (975 - 2 deduped seeder tests = 973, + 15 new unit tests = 988... wait, we're moving 15, not adding new ones. Net: 975 - 17 removed + 15 added = 973).

Actually: we remove 5+10+2=17 from DataCase, add 5+10=15 as unit. Net = -2 (the 2 seeder tests that were already covered).

## Testing strategy

- New unit tests: `ExUnit.Case, async: true`, no DB, sub-100ms each
- Remaining DataCase tests: unchanged, same coverage of DB-wired behavior
- Cross-check: markdown_test.exs already covers parse_frontmatter! with 5 tests
