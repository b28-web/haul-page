---
id: T-024-01
story: S-024
title: test-timing-telemetry
type: task
status: open
priority: high
phase: done
depends_on: [T-021-01]
---

## Context

We need hard data on what's slow before we can fix it. Add timing instrumentation to the test suite that reports per-test and per-file wall-clock times, plus compilation and setup costs.

## Acceptance Criteria

- Custom ExUnit formatter (or `setup_all`/`setup` hooks) that captures:
  - Per-test wall-clock time (not just ExUnit's reported time — include setup/teardown)
  - Per-file total time (all tests in that module)
  - Compilation time (time from `mix test` invocation to first test running)
  - Breakdown of sync vs async test files
- Output a timing report after `mix test` completes:
  - Top 20 slowest individual tests (file:line, name, duration)
  - Top 20 slowest test files (file, test count, total duration, avg per test)
  - Compilation time
  - Sync vs async split (how many files, total time in each bucket)
  - Total wall-clock time
- Report output to a file (`test/reports/timing.json` or similar) for machine parsing
- Also print a human-readable summary to stdout
- Activated via env var or mix flag: `HAUL_TEST_TIMING=1 mix test` (doesn't slow things down when off)

## Implementation notes

- ExUnit has `--trace` but it doesn't give per-file aggregates or machine-readable output
- Consider a custom ExUnit formatter module — receives `:test_finished`, `:suite_finished` events
- `mix test --formatter Haul.Test.TimingFormatter --formatter ExUnit.CLIFormatter` to run both
- Compilation time: capture `System.monotonic_time()` in test_helper.exs before `ExUnit.start()`
- Check which test files use `async: false` vs `async: true` — this alone explains the 0.6s async / 170s sync split
