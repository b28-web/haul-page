---
id: T-001-05
story: S-001
title: fly-deploy
type: task
status: open
priority: high
phase: done
depends_on: [T-001-04]
---

## Context

Configure Fly.io app and Neon Postgres. Deploy the scaffolded app so it serves a page at a public URL.

## Acceptance Criteria

- `fly.toml` configured: single region, auto_stop_machines, health check at `/healthz`
- Fly app created and accessible at `haul-page.fly.dev` (or similar)
- `DATABASE_URL` set via `fly secrets` pointing to Neon Postgres
- Migrations run on deploy
- Scale-to-zero works — app stops when idle, wakes on request
- CI deploy job added to `ci.yml` (runs on main push after test + quality pass)
