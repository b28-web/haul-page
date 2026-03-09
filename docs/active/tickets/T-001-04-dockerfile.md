---
id: T-001-04
story: S-001
title: dockerfile
type: task
status: open
priority: high
phase: done
depends_on: [T-001-03]
---

## Context

Create the multi-stage Dockerfile for building a Phoenix release. This is the build artifact that Fly.io deploys.

## Acceptance Criteria

- Multi-stage Dockerfile: build stage (compile + assets + release) and runtime stage
- Runtime stage uses minimal Debian image, no Elixir/Erlang/Node installed
- Release includes embedded ERTS
- `bin/migrate_and_start` script runs migrations then starts the app
- `docker build .` succeeds locally
- Final image < 100MB
