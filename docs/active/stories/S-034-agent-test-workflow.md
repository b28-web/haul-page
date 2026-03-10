---
id: S-034
title: agent-test-workflow
status: open
epics: [E-013, E-014]
---

## Agent Test Workflow Optimization

S-033 improves test *architecture* (what tests exist, how they're structured). This story improves test *execution* — how agents and developers run tests, and what they pay per invocation.

Problem: agents call `mix test` (full suite, ~97s) many times per ticket during the RDSPI workflow. Even when a ticket touches 2 files, the agent runs all 975 tests. This is the biggest multiplier on total compute time across a `lisa loop` session.

### Diagnosis

| Issue | Impact | Fix |
|-------|--------|-----|
| Agents run full suite during implementation | 97s × N invocations per ticket | `mix test --stale` during impl, full suite only at review |
| No setup_all for worst offenders | `superadmin_qa_test.exs` creates 54 schemas (3/test × 18) | `setup_all` for files that don't test isolation |
| Agent RDSPI workflow doesn't enforce targeted tests | Agents default to `mix test` out of caution | Update workflow docs + CLAUDE.md |

### What this story addresses

1. **`mix test --stale` as the agent default** — only re-runs tests whose source changed. Zero code change, massive per-invocation savings
2. **`setup_all` quick wins** — mechanical conversion of worst-offender files that create schemas per-test unnecessarily
3. **Agent workflow guidance** — update RDSPI workflow and CLAUDE.md to enforce targeted testing during implementation

### What this story does NOT address (covered by S-033)

- Mocking / test tier changes — S-033 handles test architecture
- QA deduplication — S-033 T-033-04
- Async unlock — S-033 T-033-05

## Tickets

- T-034-01: stale-test-default — make `mix test --stale` the documented agent default, update CLAUDE.md and RDSPI workflow
- T-034-02: setup-all-quick-wins — convert top 5 worst-offender test files from `setup` to `setup_all`
- T-034-03: agent-test-targeting — add `just test-stale` recipe and document the targeted test workflow

## Acceptance criteria

- `mix test --stale` documented as the default agent command during implementation
- Top 5 worst-offender files converted to `setup_all` (saves ~25s cumulative)
- `just test-stale` recipe exists and works
- Full suite (`mix test`) still passes — `setup_all` changes cause no regressions
- Agent workflow docs updated with clear test execution guidance
