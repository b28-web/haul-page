# T-024-01 Structure: Test Timing Telemetry

## Files Modified

### test/test_helper.exs
- Add conditional formatter registration based on `HAUL_TEST_TIMING` env var
- Record compile-end timestamp in Application env when timing enabled
- Preserve existing `exclude: [:baml_live]` and Sandbox config

### .gitignore
- Add `test/reports/` to gitignore (generated output, not committed)

## Files Created

### test/support/timing_formatter.ex
Module: `Haul.Test.TimingFormatter`

Implements: `GenServer` (ExUnit formatter protocol)

**Public interface:** None — instantiated by ExUnit automatically via formatters config.

**GenServer callbacks:**
- `init/1` — reads `:haul, :test_timing` from Application env, initializes accumulator state
- `handle_cast({:suite_started, opts}, state)` — records suite start monotonic time
- `handle_cast({:test_finished, %ExUnit.Test{}}, state)` — appends test timing data to accumulator
- `handle_cast({:module_finished, %ExUnit.TestModule{}}, state)` — appends module timing data
- `handle_cast({:suite_finished, times_us}, state)` — triggers report generation, writes JSON, prints stdout summary
- All other events — ignored (no-op)

**Private functions:**
- `build_report/1` — transforms accumulated state into report map
- `print_summary/1` — formats report as human-readable text to stdout
- `write_json/1` — serializes report to `test/reports/timing.json`
- `format_duration/1` — converts microseconds to human-readable string (e.g., "1,234ms")

**State shape:**
```elixir
%{
  compile_end_ms: integer() | nil,
  suite_start_ms: integer() | nil,
  tests: list(test_entry),
  modules: list(module_entry)
}
```

### test/reports/ (directory)
- Created at runtime by the formatter
- Contains `timing.json` output
- Gitignored

### test/haul/test/timing_formatter_test.exs
Module: `Haul.Test.TimingFormatterTest`

Tests:
- Formatter accumulates test data from mock events
- Report correctly identifies top slowest tests and files
- Sync/async split is computed correctly
- JSON output is valid and contains required fields
- Human-readable output contains expected sections
- Duration formatting works correctly

## Module Boundaries

```
ExUnit (framework)
  └── starts TimingFormatter as GenServer
      └── receives events during test run
      └── at suite_finished:
          ├── build_report/1 (pure data transform)
          ├── print_summary/1 (IO side effect)
          └── write_json/1 (File side effect)
```

The formatter is completely self-contained. No other modules depend on it. It's only instantiated when HAUL_TEST_TIMING=1.

## Ordering

1. Create test/support/timing_formatter.ex (the formatter module)
2. Modify test/test_helper.exs (conditional activation)
3. Add test/reports/ to .gitignore
4. Create test for the formatter
5. Verify end-to-end with `HAUL_TEST_TIMING=1 mix test`
