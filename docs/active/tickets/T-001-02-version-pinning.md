---
id: T-001-02
story: S-001
title: version-pinning
type: task
status: open
priority: high
phase: done
depends_on: [T-001-01]
---

## Context

Pin Elixir and Erlang versions so that local dev, CI, and Docker builds all use the same versions.

## Acceptance Criteria

- `.tool-versions` or `mise.toml` at repo root pins Elixir 1.19.x and Erlang/OTP 28.x
- Versions match what's used in the CI workflow and Dockerfile build stage
- Running `mise install` in the repo sets up the correct versions
