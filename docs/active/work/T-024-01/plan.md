# T-024-01 Plan: Test Timing Telemetry

## Step 1: Create the TimingFormatter module

File: `test/support/timing_formatter.ex`

Implement the full GenServer with all callbacks:
- init: read Application env for compile_end timestamp
- suite_started: record start time
- test_finished: accumulate test entry (module, name, file, line, time_us, async)
- module_finished: accumulate module entry (name, file, test_count, total_time, async)
- suite_finished: build report, print summary, write JSON

Include report building (sort tests/modules by time, compute sync/async splits, top-20 lists) and both output functions.

**Verify:** Module compiles with `mix compile`

## Step 2: Modify test_helper.exs

Add conditional formatter activation:
```elixir
if System.get_env("HAUL_TEST_TIMING") == "1" do
  Application.put_env(:haul, :test_timing, %{
    compile_end: System.monotonic_time(:millisecond)
  })
  ExUnit.start(
    exclude: [:baml_live],
    formatters: [ExUnit.CLIFormatter, Haul.Test.TimingFormatter]
  )
else
  ExUnit.start(exclude: [:baml_live])
end
```

Keep the Sandbox line unchanged.

**Verify:** `mix test --max-cases 1` still works normally (no env var = no change)

## Step 3: Gitignore test/reports/

Add `test/reports/` to `.gitignore`.

**Verify:** File is listed in .gitignore

## Step 4: Write formatter unit test

File: `test/haul/test/timing_formatter_test.exs`

Test the formatter by:
1. Starting it as a GenServer
2. Sending it mock ExUnit events (suite_started, test_finished × N, module_finished × N, suite_finished)
3. Verifying the JSON file was written with correct structure
4. Verifying stdout output contains expected sections

Tests:
- `test "produces timing report with slowest tests"` — send events, check JSON
- `test "computes sync vs async split"` — mix of async true/false modules
- `test "handles empty test suite"` — no tests, still produces valid report
- `test "format_duration converts microseconds correctly"` — unit test helper

**Verify:** `mix test test/haul/test/timing_formatter_test.exs`

## Step 5: End-to-end verification

Run `HAUL_TEST_TIMING=1 mix test` (or a subset) and verify:
1. Normal test output still appears (CLIFormatter active)
2. Timing summary prints to stdout after tests complete
3. `test/reports/timing.json` is created with valid JSON
4. JSON contains all required fields: slowest_tests, slowest_files, compilation_ms, sync_async, wall_clock_ms

**Verify:** Manual inspection of output + JSON file

## Step 6: Run full test suite

Run `mix test` (without env var) to confirm zero impact on normal workflow.
Run `HAUL_TEST_TIMING=1 mix test` to confirm full report.

**Verify:** All 742+ tests pass in both modes
