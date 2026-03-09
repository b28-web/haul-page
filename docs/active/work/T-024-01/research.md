# T-024-01 Research: Test Timing Telemetry

## Current Test Infrastructure

### test_helper.exs (3 lines)
```elixir
ExUnit.start(exclude: [:baml_live])
Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)
```
- No custom formatters, no timing capture, no ExUnit.configure calls
- Sandbox mode is `:manual` — each test case sets up its own transaction

### Test File Statistics
- **84 test files** total (~11,673 LOC)
- **29 async: true** — isolated unit tests (AI modules, content loader, controllers, sandboxed adapters)
- **52 async: false** — database/multi-tenant tests (LiveViews, Ash resources, workers, integration)
- **3 untagged** — default to sync
- Ticket notes mention "0.6s async / 170s sync split" — confirms sync tests dominate wall-clock time

### Test Support Modules
- `test/support/conn_case.ex` — HTTP test template. Setup: sandbox, conn, auth helpers, tenant cleanup
- `test/support/data_case.ex` — Data layer template. `setup_sandbox/1` with shared mode for sync tests
- `test/support/fixtures/test_image.jpg` — upload testing

### mix.exs Test Config
- `elixirc_paths(:test)` includes `["lib", "test/support"]`
- Test alias: `test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]`
- Test deps: lazy_html, ex_machina, credo, dialyxir

### config/test.exs
- Sandbox pool with `pool_size: System.schedulers_online() * 2`
- All external adapters sandboxed (SMS, payments, billing, AI, places)
- Oban: `testing: :manual`
- Server: false (no HTTP server by default)
- Logger: `:warning` level

### Existing Timing/Telemetry Code
- **One manual timing example** in signup_flow_test.exs: `System.monotonic_time(:millisecond)` + Logger.info
- **One telemetry test** in cost_tracker_test.exs: uses `:telemetry_test` for AI cost events
- **No custom ExUnit formatters anywhere in codebase**
- **No test/reports/ directory**

## ExUnit Formatter API

ExUnit formatters implement `GenServer` and receive these events:
- `{:suite_started, opts}` — suite begins
- `{:module_started, %ExUnit.TestModule{}}` — module begins (has `file` and `name`)
- `{:test_started, %ExUnit.Test{}}` — individual test begins
- `{:test_finished, %ExUnit.Test{}}` — individual test finishes (has `time` in microseconds)
- `{:module_finished, %ExUnit.TestModule{}}` — module finishes (has `tests` list)
- `{:suite_finished, times_us}` — suite ends (has `run` and `async` times)

Key fields on `%ExUnit.Test{}`:
- `time` — test duration in microseconds (set by ExUnit, includes setup)
- `module` — test module atom
- `name` — test name atom
- `tags` — includes `file`, `line`, `async`, `describe`

Key fields on `%ExUnit.TestModule{}`:
- `file` — source file path
- `name` — module atom
- `tests` — list of `%ExUnit.Test{}` structs (available in module_finished)

### Formatter Registration
```elixir
# Via CLI
mix test --formatter Haul.Test.TimingFormatter --formatter ExUnit.CLIFormatter

# Via ExUnit.start
ExUnit.start(formatters: [ExUnit.CLIFormatter, Haul.Test.TimingFormatter])
```

Multiple formatters can run simultaneously. The default CLIFormatter handles normal output.

## Compilation Time Measurement

No built-in ExUnit hook for compilation time. Options:
1. Capture `System.monotonic_time()` in test_helper.exs before `ExUnit.start()` — measures time from helper execution to... nothing (need end marker)
2. Use a mix task wrapper that records start time, runs `mix test`, computes delta
3. Record timestamp in test_helper.exs, formatter reads it from Application env at suite_started

Best approach: test_helper.exs stores `System.monotonic_time()` in Application env before ExUnit.start(). The formatter reads it at suite_started to compute compilation time (time between mix invocation and first test).

Actually simpler: test_helper.exs runs after compilation. So `System.monotonic_time()` captured there represents "compilation is done, tests about to start." The formatter's suite_started captures "tests are starting." The delta is small (just ExUnit setup).

For compilation time, we need the time from `mix test` invocation to test_helper.exs execution. A mix task wrapper or env var with timestamp is needed. Simplest: test_helper.exs captures its own timestamp, and the formatter uses suite_finished's total time. The compilation time = wall_clock_total - suite_run_time.

## Activation Mechanism

Ticket requires: `HAUL_TEST_TIMING=1 mix test`

Options:
1. Conditionally add formatter in test_helper.exs based on env var
2. Use a mix task alias that sets the formatter
3. ExUnit.configure in test_helper.exs when env var present

Option 1 is simplest and matches the ticket spec.

## Output Requirements

1. **stdout** — human-readable summary after test run
2. **test/reports/timing.json** — machine-parseable JSON file

Report must include:
- Top 20 slowest individual tests (file:line, name, duration)
- Top 20 slowest test files (file, test count, total duration, avg per test)
- Compilation time
- Sync vs async split (file count, total time per bucket)
- Total wall-clock time

## Constraints

- Must not slow down normal test runs (only active when env var set)
- Formatter module must be in test/support/ (compiled only in :test env)
- JSON output needs Jason (already a dependency via Phoenix)
- No new dependencies needed
