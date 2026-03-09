---
id: T-001-03
story: S-001
title: ci-pipeline
type: task
status: open
priority: high
phase: ready
depends_on: [T-001-02]
---

## Context

Set up GitHub Actions CI with test and quality jobs. No deploy job yet — that comes after Fly.io is configured.

## Acceptance Criteria

- `.github/workflows/ci.yml` exists
- `test` job: Postgres 16 service, `mix deps.get`, `mix compile --warnings-as-errors`, `mix test`
- `quality` job: `mix format --check-formatted`, `mix credo --strict`, `mix dialyzer`
- Both jobs use `erlef/setup-beam` with pinned versions matching `.tool-versions`
- Deps and `_build` are cached by `mix.lock` hash
- Pipeline passes on a clean push
