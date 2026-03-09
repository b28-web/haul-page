---
id: T-001-06
story: S-001
title: mix-setup
type: task
status: open
priority: medium
phase: ready
depends_on: [T-001-05]
---

## Context

Ensure `mix setup` is a reliable one-liner for new contributors. Phoenix generates a default setup alias — verify it works end-to-end and add any missing steps.

## Acceptance Criteria

- `mix setup` runs: deps.get, deps.compile, db create, db migrate, seeds, assets setup
- Works from a clean clone with only Elixir/Erlang and Postgres available
- Dev seeds create a sample operator with realistic data
- `mix phx.server` starts successfully after `mix setup`
