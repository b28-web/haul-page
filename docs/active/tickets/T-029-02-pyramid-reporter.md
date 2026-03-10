---
id: T-029-02
story: S-029
title: pyramid-reporter
type: task
status: open
priority: low
phase: done
depends_on: [T-029-01]
---

## Context

Without visibility into the test pyramid shape, it drifts silently toward integration-heavy. A simple reporting tool makes the ratio visible.

## Acceptance Criteria

- Create `lib/mix/tasks/haul/test_pyramid.ex` — a mix task that reports the test pyramid shape
- Output:
  ```
  Test Pyramid Report
  ───────────────────
  Tier 1 (Unit):        142 tests in 25 files   (17%)  ████
  Tier 2 (Resource):    203 tests in 22 files   (24%)  ██████
  Tier 3 (Integration): 500 tests in 48 files   (59%)  ██████████████
  ───────────────────
  Total: 845 tests in 95 files
  Target: 40% / 30% / 30%
  ```
- Detection logic:
  - Tier 1: files using `ExUnit.Case` (not DataCase or ConnCase)
  - Tier 2: files using `Haul.DataCase`
  - Tier 3: files using `HaulWeb.ConnCase`
- Add `just test-pyramid` recipe
- Write tests for the mix task itself (Tier 1 — it's pure file parsing)

## Implementation Notes

- Parse `use` declarations in test files — don't run the test suite
- Handle edge cases: files with `use ExUnit.Case` that also import DataCase helpers
- The percentages are approximate — some ConnCase tests are really Tier 2 level but mounted via ConnCase for convenience. That's fine; the report shows the structural shape, not a precise classification.
- Keep it simple — a 50-line mix task, not a framework
