# T-024-01 Design: Test Timing Telemetry

## Decision: Custom ExUnit Formatter + test_helper.exs Instrumentation

### Approach: Single GenServer Formatter

A custom ExUnit formatter module (`Haul.Test.TimingFormatter`) that implements `GenServer`, receives all test events, accumulates timing data, and produces both stdout and JSON reports at suite end.

**Why this approach:**
- ExUnit's formatter API is purpose-built for this — receives all lifecycle events with timing data
- Runs alongside the default CLIFormatter (no output disruption)
- GenServer state cleanly accumulates per-test and per-module data
- No external dependencies, no mix task wrappers, no monkey-patching

### Rejected Alternatives

**A. setup_all/setup hooks in each test module**
- Would require modifying all 84 test files
- Can't capture cross-module aggregates or compilation time
- Invasive and fragile

**B. Mix task wrapper**
- A custom `mix timing_test` that wraps `mix test`
- Adds complexity (another entry point) and can't access ExUnit internals
- Would need process spawning and stdout parsing

**C. Telemetry-based approach**
- ExUnit doesn't emit `:telemetry` events natively
- Would require patching ExUnit or wrapping every test — same problem as A

### Architecture

```
test_helper.exs
  ├── Records compile_end timestamp in Application env
  ├── Conditionally adds TimingFormatter when HAUL_TEST_TIMING=1
  └── ExUnit.start(formatters: [...])

Haul.Test.TimingFormatter (GenServer)
  ├── init/1 — read compile_end from App env, record suite_start
  ├── handle_cast(:suite_started) — record suite start time
  ├── handle_cast(:test_finished) — accumulate test data
  ├── handle_cast(:module_finished) — accumulate module data
  └── handle_cast(:suite_finished) — compute report, write JSON, print summary
```

### Compilation Time Strategy

The test_helper.exs file runs after all compilation is complete. We record `System.monotonic_time(:millisecond)` there. The formatter records its own start time at `suite_started`. The difference between these two is negligible (ExUnit setup time).

For true compilation time, we set an env var with the current timestamp at the very start of the mix alias, and test_helper.exs reads it:

```elixir
# In test_helper.exs (when timing enabled):
compile_end = System.monotonic_time(:millisecond)
Application.put_env(:haul, :test_timing, %{compile_end: compile_end})
```

The formatter at `suite_finished` gets `times_us` map which includes `run` (total test execution time in microseconds). The wall-clock time minus run time approximates compilation + setup overhead.

Simpler approach: just measure wall-clock from test_helper.exs to suite_finished. This captures "time from compilation done to suite done." For compilation time itself, we use `System.monotonic_time()` in a compile-time module attribute vs test_helper.exs runtime — but this is fragile.

**Final decision:** Record `System.monotonic_time(:millisecond)` in test_helper.exs. The formatter records its own time at suite_started and suite_finished. Report:
- `compilation_ms` = suite_started_time - test_helper_time (approximation — includes ExUnit boot)
- `test_run_ms` = from suite_finished times_us
- `wall_clock_ms` = suite_finished_time - test_helper_time

### Data Model (GenServer State)

```elixir
%{
  test_helper_time: integer(),      # from Application env
  suite_start_time: integer(),      # monotonic ms at suite_started
  tests: [                          # accumulated from test_finished events
    %{
      module: atom(),
      name: atom(),
      file: String.t(),
      line: integer(),
      time_us: integer(),
      async: boolean(),
      tags: map()
    }
  ],
  modules: [                        # accumulated from module_finished events
    %{
      name: atom(),
      file: String.t(),
      test_count: integer(),
      total_time_us: integer(),
      async: boolean()
    }
  ]
}
```

### Activation

```elixir
# test_helper.exs
if System.get_env("HAUL_TEST_TIMING") == "1" do
  compile_end = System.monotonic_time(:millisecond)
  Application.put_env(:haul, :test_timing, %{compile_end: compile_end})
  ExUnit.start(
    exclude: [:baml_live],
    formatters: [ExUnit.CLIFormatter, Haul.Test.TimingFormatter]
  )
else
  ExUnit.start(exclude: [:baml_live])
end
```

This is zero-cost when the env var is not set — the formatter module is compiled (it's in test/support/) but never instantiated.

### Output Format

**stdout (human-readable):**
```
=== Test Timing Report ===

Compilation + setup: 12,345ms
Test execution:      170,456ms
Total wall-clock:    182,801ms

--- Sync vs Async ---
Sync files:  52 (168,234ms)
Async files: 29 (2,222ms)

--- Top 20 Slowest Tests ---
  1. 4,521ms  test/haul_web/live/booking_live_test.exs:45 — "creates booking with photos"
  ...

--- Top 20 Slowest Files ---
  1. 12,345ms  test/haul_web/live/app/services_live_test.exs (15 tests, avg 823ms)
  ...
```

**JSON (test/reports/timing.json):**
```json
{
  "compilation_ms": 12345,
  "test_run_ms": 170456,
  "wall_clock_ms": 182801,
  "sync_async": { "sync_files": 52, "async_files": 29, ... },
  "slowest_tests": [...],
  "slowest_files": [...],
  "all_tests": [...],
  "all_files": [...]
}
```

JSON includes ALL tests and files (not just top 20) for machine analysis.

### File Placement

- `test/support/timing_formatter.ex` — the formatter module (compiled in :test env)
- `test/reports/` — output directory (gitignored)
- `test/test_helper.exs` — modified to conditionally enable formatter

### Testing the Formatter

A unit test for the formatter itself: create it, send it mock events, verify output. This validates the aggregation logic without running the full suite.
