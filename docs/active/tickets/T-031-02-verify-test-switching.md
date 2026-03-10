---
id: T-031-02
story: S-031
title: verify-test-switching
type: task
status: open
priority: low
phase: done
depends_on: [T-031-01]
---

## Context

After switching to `compile_env`, verify that sandbox adapters activate correctly in test and real adapters activate in dev/prod. This is a verification ticket — the change in T-031-01 should work, but adapter dispatch is critical infrastructure.

## Acceptance Criteria

- Full test suite passes (sandbox adapters compiled in from config/test.exs)
- Dev server starts and uses real adapters (verify with `mix phx.server` + manual check)
- Document in `docs/knowledge/test-architecture.md` (or existing docs):
  - How adapter switching works (compile-time via config/test.exs)
  - How to add a new adapter (define behaviour implementation + set in config)
  - Note that recompilation is needed after config changes
- Check edge case: `config/runtime.exs` overrides — if any adapter is set in runtime.exs, `compile_env` won't see it. Verify no adapters are configured in runtime.exs.
- Verify CI pipeline compiles with correct config (config/test.exs)

## Implementation Notes

- If any adapter MUST be switchable at runtime (unlikely for this app), keep `Application.get_env` for that one and document why
- The sandbox modules use `Process.get/put` for per-test overrides — this still works because the sandbox module itself is the adapter; internal overrides are within the sandbox
