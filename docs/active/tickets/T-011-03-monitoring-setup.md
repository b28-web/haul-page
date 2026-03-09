---
id: T-011-03
story: S-011
title: monitoring-setup
type: task
status: open
priority: medium
phase: ready
depends_on: [T-001-05]
---

## Context

Set up basic monitoring so we know when a production deploy is unhealthy. Fly health checks cover liveness, but we need error tracking and uptime alerting.

## Acceptance Criteria

- Error tracking service configured (Sentry or Honeybadger):
  - Elixir SDK added to mix.exs
  - Plug integration captures unhandled exceptions
  - DSN set via Fly secret (not in code)
  - Test error endpoint verifies integration in dev
- Uptime monitoring:
  - Fly health checks at `/healthz` (already exists)
  - External uptime monitor pinging the public URL (BetterStack free tier or equivalent)
  - Alert on downtime via email or Slack
- No performance monitoring yet — keep it simple
