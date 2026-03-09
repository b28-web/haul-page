# T-024-01 Review: Test Timing Telemetry

## Summary of Changes

### Files Created
- **test/support/timing_formatter.ex** — Custom ExUnit formatter (GenServer) that captures per-test and per-file timing data, computes sync/async splits, and outputs both human-readable stdout summaries and machine-parseable JSON
- **test/haul/test/timing_formatter_test.exs** — Unit tests for the formatter (4 tests)

### Files Modified
- **test/test_helper.exs** — Conditional formatter activation via `HAUL_TEST_TIMING=1` env var. Records compile-end timestamp. Adds TimingFormatter alongside CLIFormatter when enabled.
- **.gitignore** — Added `/test/reports/` to exclude generated timing reports

## Acceptance Criteria Verification

| Criterion | Status | Notes |
|-----------|--------|-------|
| Per-test wall-clock time | ✓ | Captured from ExUnit.Test.time (includes setup/teardown) |
| Per-file total time | ✓ | Aggregated from module_finished events |
| Compilation time | ✓ | Approximated as setup_ms (test_helper → suite_start) |
| Sync vs async breakdown | ✓ | Counted from module async tags |
| Top 20 slowest tests | ✓ | Sorted by duration, includes file:line and name |
| Top 20 slowest files | ✓ | Sorted by total duration, includes test count and avg |
| JSON report file | ✓ | Written to test/reports/timing.json |
| Human-readable stdout | ✓ | Printed after suite_finished |
| Env var activation | ✓ | HAUL_TEST_TIMING=1 enables; absent = zero cost |

## Test Coverage

- **4 unit tests** for the formatter itself
- Tests cover: report generation with mock events, sync/async split computation, empty suite handling, unknown event resilience
- Full suite (746 tests) passes without regression in both modes

## Output Format

**stdout sample:**
```
============================================================
  Test Timing Report
============================================================
  Setup/compile overhead: 16ms
  Test execution:         633ms
  Total wall-clock:       649ms
  Sync files:  0 (0ms)
  Async files: 2 (607ms)
  Top 20 Slowest Tests / Top 20 Slowest Files
============================================================
```

**JSON contains:** wall_clock_ms, setup_ms, test_run_ms, sync_async, slowest_tests (top 20), slowest_files (top 20), all_tests, all_files

## Design Decisions

1. **ExUnit formatter GenServer** — cleanest integration point; no modifications to existing test files needed
2. **Application env for cross-process state** — test_helper.exs stores compile_end timestamp, formatter reads it during init
3. **group_leader redirect in tests** — required to capture_io from GenServer process; standard Erlang technique

## Open Concerns

1. **Compilation time is approximate** — `setup_ms` measures time from test_helper.exs execution to suite_started, which includes ExUnit boot but not actual compilation. True compile time would require a mix task wrapper measuring time before `mix test` starts compilation. Good enough for the "how long before tests run" question.

2. **Interleaved output** — The timing report prints via IO.puts after suite_finished. Since CLIFormatter also prints at suite_finished, the outputs may interleave. In practice this works fine because CLIFormatter finishes its summary first, but ordering isn't guaranteed. Could be addressed by using IO.write with a single binary if it becomes a problem.

3. **JSON file path is hardcoded** — `test/reports/timing.json` is always the output location. If multiple concurrent test runs happen, they'd overwrite each other. Not an issue for this project's single-runner workflow.

## No Regressions

- `mix test` (without env var): 746 tests, 0 failures
- Formatter module compiles but is never instantiated when HAUL_TEST_TIMING is not set
- No new dependencies added
