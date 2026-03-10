---
id: T-026-02
story: S-026
title: verify-and-document
type: task
status: open
priority: medium
phase: done
depends_on: [T-026-01]
---

## Context

After switching to native Postgres, update all developer-facing docs to reflect the new setup. Remove Docker as a prerequisite for local development. The Dockerfile stays — it's used by Fly.io remote builders for production deploys.

## Acceptance Criteria

- Update DEPLOYMENT.md:
  - "Local deploy" section no longer assumes Docker for Postgres
  - Add native Postgres setup instructions (brew/mise)
  - Keep Docker instructions only for "test the release image locally" (optional)
- Update `just llm` output (`.just/system.just` `_llm` recipe) to reflect:
  - No Docker dependency for dev
  - `.mise.toml` as toolchain source of truth
  - Native Postgres 18
- Update any just recipes that reference Docker for dev
- Verify fresh clone workflow: `mise install && mix setup && mix test` works end-to-end
- Add to OVERVIEW.md blockers/decisions: Docker Desktop no longer required for dev
