---
id: T-024-04
story: S-024
title: agent-test-targeting
type: task
status: open
priority: medium
phase: done
depends_on: [T-024-03]
---

## Context

Even with a faster full suite, agents shouldn't need to run all 600+ tests to validate a change to a single module. Give agents a way to run just the tests relevant to their ticket, with a final full-suite check before marking done.

## Acceptance Criteria

- Document a convention for agents to run targeted tests:
  - `mix test test/haul/billing_test.exs` — single file
  - `mix test test/haul/billing_test.exs test/haul_web/live/app/billing_live_test.exs` — related files
  - `mix test --only tag:billing` — tag-based (if we add tags)
- Add a mapping file or script `test/test_map.exs` (or section in CLAUDE.md) that maps:
  - Source modules → relevant test files
  - Stories/domains → test file globs
  - e.g., "if you changed lib/haul/billing/*, run test/haul/billing_test.exs + test/haul_web/live/app/billing_live_test.exs"
- Update the RDSPI workflow docs to recommend:
  - During implement: run targeted tests after each change
  - Before review: run full suite once
- Verify: targeted test runs complete in under 15 seconds for typical ticket scope
