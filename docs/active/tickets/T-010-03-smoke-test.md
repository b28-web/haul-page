---
id: T-010-03
story: S-010
title: smoke-test
type: task
status: open
priority: medium
phase: ready
depends_on: [T-010-01, T-010-02]
---

## Context

Two public pages were broken without any test catching it. The existing test suite (86 tests) covers domain logic and some controller routes, but doesn't verify that every public page renders a 200 with no crashes.

This ticket adds a lightweight smoke test that hits every public route and asserts a successful response. This prevents future regressions where a template references an unset assign, a missing import, or a broken data dependency.

## Implementation

Add a test file (e.g., `test/haul_web/smoke_test.exs`) that:

1. For each public route (`/`, `/scan`, `/book`, `/scan/qr`):
   - `GET` the path via `ConnTest`
   - Assert `200` status (or `302` for redirects, as appropriate)
   - Assert no `500` response
2. Use `Haul.DataCase` or `ConnCase` with proper tenant setup if needed
3. Keep it simple — no DOM assertions, just "does it render without crashing"

## Acceptance Criteria

- `mix test test/haul_web/smoke_test.exs` passes
- All public routes return non-500 responses
- Test runs in < 2 seconds (no browser, just ConnTest)
- If a future change breaks a page render, this test fails
