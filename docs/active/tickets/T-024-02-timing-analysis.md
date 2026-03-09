---
id: T-024-02
story: S-024
title: timing-analysis
type: spike
status: open
priority: high
phase: ready
depends_on: [T-024-01]
---

## Context

Run the timing telemetry from T-024-01 and produce a diagnostic report. Identify the root causes of the ~170s test runtime and categorize them.

## Acceptance Criteria

- Run `HAUL_TEST_TIMING=1 mix test` and capture the timing report
- Analyze and document in `docs/active/work/T-024-02/analysis.md`:
  - **Top 10 slowest test files** with per-test breakdown
  - **Async audit:** list every `async: false` file and why (tenant state? DB conflicts? Oban? could it be async?)
  - **Setup cost:** which files have expensive `setup` or `setup_all` blocks (tenant provisioning, seed data, etc.)
  - **Compilation cost:** how much of the 170s is compilation vs actual test execution
  - **Categorize bottlenecks:**
    - Tests that are inherently slow (browser QA, integration tests)
    - Tests that are slow due to fixable setup (redundant provisioning, unnecessary seeding)
    - Tests that could be async but aren't
    - Tests with sleeps or timeouts baked in
- Produce a prioritized list of fixes: which changes would yield the biggest time savings
- Estimate projected runtime after fixes

## Output

The work artifact `analysis.md` becomes the roadmap for T-024-03.
