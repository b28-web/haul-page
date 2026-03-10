---
id: T-034-03
story: S-034
title: agent-test-targeting
type: task
status: open
priority: medium
phase: done
depends_on: []
---

## Context

The RDSPI workflow and CLAUDE.md both mention targeted testing but don't enforce it strongly enough. Agents default to `mix test` because it's safe. We need explicit guidance and tooling so agents reach for the fast path first.

## Acceptance Criteria

- Add `just test-stale` recipe:
  ```
  test-stale:
    mix test --stale --max-failures 5
  ```
- Add `just test-file FILE` recipe:
  ```
  test-file FILE:
    mix test {{FILE}}
  ```
- Update the `_llm` recipe in `.just/system.just` to mention `--stale` as the default test command
- Update RDSPI workflow (`docs/knowledge/rdspi-workflow.md`) implementation phase:
  - "After each change, run `mix test --stale` (not `mix test`)"
  - "Run targeted tests for the specific domain you changed (see CLAUDE.md test mapping)"
  - "Only run `mix test` in the review phase"
- Verify `just test-stale` works from a lisa-spawned agent shell (mise shims, PATH, etc.)

## Implementation Notes

- This is a documentation + justfile change, no source code
- The `just test-stale` recipe should mirror the existing `just test` recipe but add `--stale`
- Consider adding a timing note: "`mix test --stale` typically runs in 5-15s vs 97s for full suite"
