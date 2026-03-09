# T-011-03 Review: Monitoring Setup

## Summary

Added Sentry error tracking (v12.0.2) to the application. Errors are captured automatically via Logger handler and Plug context enrichment. DSN configured via `SENTRY_DSN` Fly secret — no-op when unset.

## Files Changed

### Modified
- **mix.exs** — Added `{:sentry, "~> 12.0"}` dependency
- **config/config.exs** — Sentry base config: environment_name, source_code_context, root_source_code_paths
- **config/runtime.exs** — Runtime DSN loading from `SENTRY_DSN` env var
- **lib/haul_web/endpoint.ex** — Added `plug Sentry.PlugContext` for request context enrichment
- **lib/haul/application.ex** — Added `:logger.add_handler` for Sentry.LoggerHandler

### Created
- **lib/haul_web/controllers/debug_controller.ex** — Dev-only test error endpoint at `/dev/sentry-test`
- **lib/haul_web/router.ex** — Added debug route in existing dev scope
- **test/haul_web/controllers/debug_controller_test.exs** — Verifies route is dev-only (404 in test)
- **test/haul/sentry_config_test.exs** — Verifies Sentry config (DSN nil, env name, source context)

## Test Coverage

- **212 tests, 0 failures** (up from 208)
- 4 new tests: 1 debug controller, 3 Sentry config assertions
- All existing tests pass — Sentry has no side effects when DSN is nil
- No integration test for actual Sentry event delivery (would require real DSN)

## Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| Elixir SDK added to mix.exs | ✅ | sentry ~> 12.0 |
| Plug integration captures unhandled exceptions | ✅ | Sentry.PlugContext + LoggerHandler |
| DSN set via Fly secret (not in code) | ✅ | `SENTRY_DSN` env var in runtime.exs |
| Test error endpoint verifies integration in dev | ✅ | `/dev/sentry-test` raises RuntimeError |
| Fly health checks at `/healthz` | ✅ | Already existed (T-001-05) |
| External uptime monitor | ⚠️ | Operational setup, not code — BetterStack/UptimeRobot config is a runbook item |
| Alert on downtime | ⚠️ | Depends on external uptime service configuration |
| No performance monitoring | ✅ | Only error tracking, no APM |

## Open Concerns

1. **Uptime monitoring is operational, not code**: The ticket mentions "external uptime monitor" and "alert on downtime." These require configuring a third-party service (BetterStack, UptimeRobot) to ping the public URL. This is a deployment/runbook task, not a code change. The `/healthz` endpoint exists and works.

2. **Fly secret not set yet**: `SENTRY_DSN` must be set via `fly secrets set SENTRY_DSN=<dsn>` after creating a Sentry project. Until then, error tracking is a no-op.

3. **Source code context in releases**: For source code context to work in production releases, `mix sentry.package_source_code` should be added to the release build. Currently not in the Dockerfile — low priority since stack traces are still useful without source context.

4. **No Oban-specific integration**: Sentry v12 captures Oban job failures via the Logger handler (OTP crash reports). If more granular Oban context is needed later, Sentry v12 has an `integrations: [oban: [...]]` config option that can be added.
