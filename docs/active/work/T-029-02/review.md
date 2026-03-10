# T-029-02 Review: pyramid-reporter

## Summary

Created a mix task that reports the test pyramid shape by scanning test files and classifying them by tier based on their `use` declaration.

## Files Created

| File | Purpose |
|------|---------|
| `lib/mix/tasks/haul/test_pyramid.ex` | Mix task — scans test files, classifies tiers, outputs formatted report |
| `test/mix/tasks/haul/test_pyramid_test.exs` | Tier 1 tests for the mix task (10 tests, async: true) |

## Files Modified

| File | Change |
|------|--------|
| `justfile` | Added `test-pyramid` public recipe |
| `.just/system.just` | Added `_test-pyramid` private recipe |

## Test Results

Full suite: **971 tests, 0 failures** (1 excluded — baml_live tag)

New tests: 10 tests in `test_pyramid_test.exs`, all Tier 1 (ExUnit.Case, async: true). Covers:
- Tier classification for all three tiers + unknown
- Test counting with normal and edge cases
- Directory scanning including subdirectories
- Report formatting including empty results

## Acceptance Criteria Verification

- [x] `lib/mix/tasks/haul/test_pyramid.ex` created
- [x] Output matches specified format (tiers, counts, percentages, bars, totals, target)
- [x] Detection logic: ExUnit.Case → Tier 1, DataCase → Tier 2, ConnCase → Tier 3
- [x] `just test-pyramid` recipe added
- [x] Tests written at Tier 1

## Sample Output

```
Test Pyramid Report
───────────────────
  Tier 1 (Unit):          352 tests in   35 files   (36%)  ███████
  Tier 2 (Resource):      176 tests in   25 files   (18%)  ████
  Tier 3 (Integration):   448 tests in   44 files   (46%)  █████████
───────────────────
  Total: 976 tests in 104 files
  Target: 40% / 30% / 30%
```

## Design Notes

- No `app.start` required — pure file parsing, runs instantly
- Public functions (`scan_files/1`, `classify/1`, `count_tests/1`, `format_report/1`) enable Tier 1 testing
- Uses `tmp_dir` ExUnit tag for isolated test fixtures

## Open Concerns

- Test count (976) differs from OVERVIEW.md (845) because the reporter counts `test "..."` declarations via regex, while `mix test` reports ExUnit test cases. Some tests may use parameterized/dynamic test generation. The structural count is close enough for pyramid shape analysis.
- The reporter counts tests per file by regex, not by actually running ExUnit. This is by design (fast, no runtime needed) but means programmatically generated tests aren't counted.
