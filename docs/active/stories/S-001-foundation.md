---
id: S-001
title: foundation
status: open
epics: [E-001, E-002, E-007]
---

## Foundation

Scaffold the Phoenix + Ash project, establish the dev environment, CI pipeline, and deploy infrastructure. After this story, the app boots locally, tests pass in CI, and deploys to Fly.io serving a "hello world" page.

## Scope

- Phoenix project with Ash deps
- Dev tooling: formatter, credo, dialyzer
- Version pinning (mise.toml / .tool-versions)
- GitHub Actions CI (test + quality)
- Dockerfile + fly.toml
- Neon Postgres connection
- `mix setup` one-liner
