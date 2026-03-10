---
id: T-025-03
story: S-025
title: timing-verification
type: task
status: open
priority: medium
phase: done
depends_on: [T-025-02]
---

## Context

Verify that T-025-01 and T-025-02 achieved the target. Run timing telemetry and document the before/after.

## Acceptance Criteria

- Run `HAUL_TEST_TIMING=1 mix test` and capture the timing report
- Total wall time under 45 seconds
- If target not met: document what's left and why, propose next steps
- Update `docs/active/work/T-025-03/` with before/after comparison table (same format as T-024-03 review)
- No flaky tests across 5 consecutive runs
- Full suite passes with 0 failures
