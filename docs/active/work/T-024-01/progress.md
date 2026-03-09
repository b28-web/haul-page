# T-024-01 Progress: Test Timing Telemetry

## Completed

### Step 1: TimingFormatter module ✓
- Created `test/support/timing_formatter.ex`
- GenServer implementing ExUnit formatter protocol
- Handles: suite_started, test_finished, module_finished, suite_finished
- Builds report with slowest tests, slowest files, sync/async split
- Outputs human-readable summary to stdout
- Writes machine-parseable JSON to test/reports/timing.json

### Step 2: test_helper.exs modification ✓
- Conditional activation via `HAUL_TEST_TIMING=1` env var
- Records compile_end timestamp in Application env
- Adds TimingFormatter alongside default CLIFormatter when enabled
- Zero-cost when env var not set

### Step 3: .gitignore update ✓
- Added `/test/reports/` to gitignore

### Step 4: Formatter unit tests ✓
- Created `test/haul/test/timing_formatter_test.exs`
- 4 tests: report generation, sync/async split, empty suite, unknown events
- All passing

### Step 5: End-to-end verification ✓
- `HAUL_TEST_TIMING=1 mix test` produces correct stdout summary and JSON file
- JSON validated with python json.tool

### Step 6: Full test suite ✓
- `mix test` (without env var): 746 tests, 0 failures — no regression
- `HAUL_TEST_TIMING=1 mix test` subset: works correctly with both formatters

## Deviations from plan
- None. Implementation followed plan exactly.
