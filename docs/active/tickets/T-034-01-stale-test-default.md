---
id: T-034-01
story: S-034
title: stale-test-default
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

Agents run `mix test` (full suite, ~97s) multiple times per ticket. Most tickets touch 2-5 source files, meaning 970+ of 975 tests are irrelevant on each run. `mix test --stale` only runs tests whose source dependencies changed — typically finishing in 5-15s.

This is the single highest-leverage change for agent efficiency: zero code changes, just documentation and workflow updates.

## Acceptance Criteria

- Update CLAUDE.md test targeting section:
  - During implementation: `mix test --stale` (default) or targeted file paths
  - Before review: `mix test` (full suite)
  - Document that `--stale` tracks source→test dependency via compile-time tracing
- Update `docs/knowledge/rdspi-workflow.md`:
  - Implementation phase: use `mix test --stale` after each change
  - Review phase: use `mix test` for full regression check
- Add `just test-stale` recipe to justfile as a convenience alias
- Verify `--stale` works correctly with the codebase:
  - Touch a source file, run `mix test --stale`, confirm only related tests run
  - Confirm it respects `test/support/` changes (should re-run everything when shared helpers change)

## Implementation Notes

- `mix test --stale` has been in ExUnit since Elixir 1.3. It uses compile-time module tracing to know which test files depend on which source files
- Caveat: `--stale` doesn't detect changes to config files or mix.exs. If an agent changes config, they should run the full suite
- The `--stale` flag can be combined with other flags: `mix test --stale --max-failures 3`
- This is purely a documentation/workflow change — no source code modifications needed
