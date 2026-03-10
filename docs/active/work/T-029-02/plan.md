# T-029-02 Plan: pyramid-reporter

## Step 1: Create the mix task

Create `lib/mix/tasks/haul/test_pyramid.ex` with:
- File scanning via Path.wildcard
- Tier classification via regex on `use` declarations
- Test counting via regex on `test "` lines
- Formatted output with bars, percentages, totals
- Target ratio display (40/30/30)

Verify: `mix haul.test_pyramid` produces expected output.

## Step 2: Write Tier 1 tests

Create `test/mix/tasks/haul/test_pyramid_test.exs` with:
- Tests using tmp_dir to create sample test files
- Verify classify returns correct tier for each use declaration
- Verify count_tests returns correct count
- Verify scan_files aggregates correctly
- Verify format_report produces expected output shape

Verify: `mix test test/mix/tasks/haul/test_pyramid_test.exs`

## Step 3: Add justfile recipes

- Add `_test-pyramid` private recipe to `.just/system.just`
- Add `test-pyramid` public recipe to `justfile`

Verify: `just test-pyramid` runs the mix task.

## Step 4: Full test suite

Run `mix test` to confirm nothing broken.
