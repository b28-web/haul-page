---
id: E-001
title: dev-environment
status: active
---

## Dev Environment Health

The local dev experience must stay fast, reproducible, and zero-friction. A new contributor (or a fresh machine) should go from clone to running app in under 5 minutes.

## Ongoing concerns

- Elixir/Erlang versions pinned via `.tool-versions` or `mise.toml` and match CI
- `mix setup` works end-to-end (deps, db create, migrate, seed, assets)
- Hot reload works for both Elixir code and CSS/JS assets
- Dev database seeds produce a realistic operator with sample data
- No implicit dependencies on global system state
