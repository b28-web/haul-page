---
id: T-001-01
story: S-001
title: scaffold-phoenix
type: task
status: open
priority: critical
phase: ready
depends_on: []
---

## Context

Generate the Phoenix project and add Ash ecosystem dependencies. This is the first code in the repo — everything else builds on it.

## Acceptance Criteria

- `mix phx.new` generates the app (named `haul`) inside the repo root
- `mix.exs` includes Ash core deps: ash, ash_postgres, ash_phoenix, ash_authentication, ash_state_machine, ash_oban, ash_double_entry, ash_money, ash_paper_trail, ash_archival
- Also includes: credo, dialyxir, ex_machina (test)
- `mix deps.get && mix compile` succeeds with zero warnings
- `.formatter.exs` configured for Ash DSL imports
- `.credo.exs` generated with strict defaults
