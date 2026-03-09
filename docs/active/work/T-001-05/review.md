# T-001-05 Review: Fly.io Deploy

## Summary

This ticket adds everything needed to deploy the Phoenix app to Fly.io with Neon Postgres: `fly.toml` configuration, a `/healthz` health check endpoint, SSL for Neon, and a CI deploy job fix.

## Files created

| File | Purpose |
|------|---------|
| `fly.toml` | Fly.io app config: iad region, shared-cpu-1x, 256MB, auto-stop/start, health check at `/healthz` |
| `lib/haul_web/controllers/health_controller.ex` | Returns 200 "ok" text/plain — lightweight liveness check |
| `test/haul_web/controllers/health_controller_test.exs` | Verifies GET /healthz returns 200 with correct body and content type |

## Files modified

| File | Change |
|------|--------|
| `lib/haul_web/router.ex` | Added pipeline-less `/healthz` route before browser scope |
| `config/prod.exs` | Added `/healthz` to `force_ssl` exclude paths (health checker uses HTTP) |
| `config/runtime.exs` | Enabled `ssl: true` for Ecto (Neon requires SSL) |
| `.github/workflows/ci.yml` | Removed `guardrails` from deploy `needs` (guardrails only runs on PRs, deploy only on main push) |

## Test coverage

- **New test**: `HaulWeb.HealthControllerTest` — 1 test covering GET /healthz response status, body, and content type
- **Full suite**: 12 tests, 0 failures
- **Compilation**: Clean compile, no warnings

### Coverage gaps

- No integration test for fly.toml validity (validated by flyctl on deploy)
- No test for SSL Ecto config (runtime config, validated on prod boot)
- No test verifying health check bypasses force_ssl (would need prod config in test — low value)

## Acceptance criteria mapping

| Criterion | Status | Notes |
|-----------|--------|-------|
| `fly.toml` configured: single region, auto_stop_machines, health check at `/healthz` | Done | iad region, `auto_stop_machines = "stop"`, `min_machines_running = 0` |
| Fly app accessible at `haul-page.fly.dev` | Ready | fly.toml configured; app creation + secrets are manual ops |
| `DATABASE_URL` set via `fly secrets` pointing to Neon | Ready | runtime.exs reads it; must be set manually via `fly secrets set` |
| Migrations run on deploy | Done | Dockerfile CMD is `bin/migrate_and_start` (from T-001-04) |
| Scale-to-zero works | Done | `auto_stop_machines = "stop"`, `min_machines_running = 0` |
| CI deploy job added to `ci.yml` | Done | Already existed from T-001-03; fixed `needs` dependency |

## Manual steps required before first deploy

1. `fly apps create haul-page`
2. `fly secrets set DATABASE_URL="postgres://...?sslmode=require" SECRET_KEY_BASE="$(mix phx.gen.secret)"`
3. `FLY_API_TOKEN` must be set in GitHub repo secrets
4. First deploy: `fly deploy` or push to main

## Open concerns

1. **Neon cold start + health check timing**: Neon's serverless Postgres can take ~500ms to wake. The health check is liveness-only (no DB), so this doesn't affect health checks. But the first real request after idle will see DB latency. The 10s grace period in fly.toml should cover this.

2. **Pool size**: Default 10 connections. Neon free tier allows ~100. Fine for single-machine, but if scaling to multiple machines, consider reducing per-machine pool size.

3. **Pre-existing format issues**: `config/config.exs`, `home.html.heex`, and `page_controller_test.exs` have formatting issues that predate this ticket. Not addressed here.

4. **DNS_CLUSTER_QUERY**: Set in runtime.exs but not in fly.toml env. Not needed for single-machine deploy. Will need `DNS_CLUSTER_QUERY=haul-page.internal` if scaling to multiple machines.
