---
id: T-024-03
story: S-024
title: fix-slow-tests
type: task
status: done
priority: high
phase: done
depends_on: [T-024-02]
---

## Context

Apply the fixes identified in T-024-02's analysis. Target: total test runtime under 60 seconds (from ~170s).

## Acceptance Criteria

- Implement the prioritized fixes from T-024-02's analysis. Expected categories:
  - **Flip async: false → async: true** where safe (tests that don't actually share state)
  - **Reduce setup cost** — shared tenant fixtures, lazy provisioning, cached schema creation
  - **Eliminate redundant work** — tests that seed the same data multiple times
  - **Remove unnecessary sleeps/timeouts**
  - **Optimize expensive assertions** — tests that do full DB round-trips when a unit assertion would suffice
- After fixes:
  - Run timing telemetry again — confirm improvement
  - All 624+ tests still pass
  - No new flaky tests introduced
  - Document before/after numbers in work artifact
- If under-60s target isn't achievable without test isolation risk, document what's left and why

## Non-goals

- Don't delete tests to make the suite faster
- Don't stub out real behavior to skip slow paths — keep tests meaningful
- Don't parallelize at the OS level (multiple `mix test` processes) — fix the root causes first
