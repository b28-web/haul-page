# T-033-02 Review: Extract Pure Logic

## Test Suite

`mix test` — **973 tests, 0 failures**, 91.2s (3.6s async, 87.6s sync).

Down from 975 due to removing 2 duplicate `parse_frontmatter!` tests from seeder_test.exs (already covered by 5 tests in markdown_test.exs).

## Changes

### Files created
- `test/haul/onboarding_unit_test.exs` — 5 unit tests (ExUnit.Case, async: true) for `derive_slug/1` and `site_url/1`
- `test/haul/ai/cost_tracker_unit_test.exs` — 10 unit tests (ExUnit.Case, async: true) for `estimate_tokens/1`, `estimate_cost/3`, `model_for_function/1`, `pricing/0`

### Files modified
- `test/haul/onboarding_test.exs` — Removed 5 tests (derive_slug, site_url describe blocks). 13→8 tests remain (all DB-required).
- `test/haul/ai/cost_tracker_test.exs` — Removed 10 tests (4 pure-function describe blocks). 24→14 tests remain (all DB-required).
- `test/haul/content/seeder_test.exs` — Removed 2 tests (parse_frontmatter! describe block). 6→4 tests remain. Dedup — `markdown_test.exs` already has 5 tests covering the same code path.

### Files unchanged
- All production modules (`lib/`) — no code changes needed; pure functions were already public and well-separated.

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| Extract pure functions into testable shape | Already done (S-028). Functions are public. |
| New unit tests (ExUnit.Case, async: true) cover extracted logic | Done: 15 new unit tests in 2 files |
| Original DataCase tests trimmed to DB-integration surface | Done: 17 tests removed from 3 DataCase files |
| No net loss in assertion coverage | Done: 15 moved, 2 deduped (covered by existing markdown_test.exs) |
| All tests pass | Done: 973 tests, 0 failures |

## Coverage accounting

| Source file | Removed | Added (unit) | Already covered | Net |
|------------|---------|-------------|-----------------|-----|
| onboarding_test | 5 | 5 (onboarding_unit_test) | — | 0 |
| cost_tracker_test | 10 | 10 (cost_tracker_unit_test) | — | 0 |
| seeder_test | 2 | 0 | 5 in markdown_test | -2 (dedup) |
| **Total** | **17** | **15** | **5** | **-2** |

## Test tier impact

- **15 tests moved from DataCase → ExUnit.Case**: These no longer start the Ecto sandbox. Runs in 0.01s async.
- **2 duplicate tests removed**: `parse_frontmatter!` was tested in both seeder_test.exs (DataCase) and markdown_test.exs (ExUnit.Case). The seeder delegation is just `defdelegate` — no new logic to test.

## Open concerns

- **Suite still ~91s**: This ticket's impact is about tier correctness, not speed. The 15 extracted tests were already fast (cost_tracker was async:true). Speed gains come from T-033-03 (mock service layer), T-033-04 (dedup QA), and T-033-05 (async unlock).
- **No production code changes**: The ticket anticipated needing to extract functions from modules, but S-028 already did this work. All pure functions were already public. This ticket was purely test reorganization.
- **Audit discrepancy**: T-033-01 audit listed 19 extractable tests. Actual: 15 moved + 2 deduped = 17. The audit counted `average_session_cost/0` zero case and `daily_total/1` zero case as pure, but both call `Ash.read!` internally — they need DB.
