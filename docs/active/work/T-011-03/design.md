# T-011-03 Design: Monitoring Setup

## Decision: Sentry for Error Tracking

### Options Evaluated

1. **Sentry (`sentry` hex package)**
   - Mature Elixir SDK, first-class Phoenix/Plug/Oban integration
   - Free tier: 5K errors/month, 1 user — sufficient for single-operator launch
   - Logger backend captures unhandled exceptions automatically
   - Plug integration adds request context (URL, headers, params)
   - DSN configured via single env var
   - Well-documented, widely used in Elixir community

2. **Honeybadger (`honeybadger` hex package)**
   - Also mature, good Elixir support
   - Free tier: 1 project, limited errors
   - Similar integration pattern
   - Less community adoption than Sentry in Elixir ecosystem

3. **AppSignal**
   - Combined APM + error tracking
   - Overkill for "no performance monitoring yet" requirement
   - More expensive

**Choice: Sentry** — best free tier, most mature Elixir SDK, simplest integration. Matches the "keep it simple" requirement. Single env var (`SENTRY_DSN`) to enable.

## Decision: Direct Sentry Integration (No Behaviour Wrapper)

Unlike Payments/SMS/Places, error tracking doesn't need a testable adapter abstraction:
- Sentry SDK already has a test mode (`:included_environments` config)
- In test/dev, we simply don't configure a DSN — Sentry becomes a no-op
- No business logic depends on error tracking responses
- Adding a behaviour wrapper adds complexity for no testing benefit

**Approach: Configure Sentry directly via config files. Use `:included_environments` to limit to prod.**

## Decision: Test Error Endpoint

Add `GET /debug/error` (dev-only) that raises a RuntimeError. Verifies Sentry integration works end-to-end when DSN is configured. Protected by `debug_errors` check — only available in dev.

## Decision: Uptime Monitoring Strategy

The ticket says "External uptime monitor pinging the public URL (BetterStack free tier or equivalent)." This is an operational setup, not a code change. The `/healthz` endpoint already exists and works.

**What we'll do in code:**
- Document the BetterStack/UptimeRobot setup in the onboarding runbook (T-011-01's concern)
- Keep `/healthz` as-is — simple liveness check is what Fly needs
- No code changes for uptime monitoring — it's a third-party service configuration

**What we won't do:**
- No deep health check (DB ping etc.) — adds failure modes, Fly health check is for liveness
- No custom uptime monitoring code — use existing free services

## Integration Points

### Sentry Logger Backend
- `Sentry.LoggerBackend` captures all Logger.error calls automatically
- Also captures OTP crash reports and uncaught exceptions
- No code changes needed in existing Logger calls

### Sentry Plug
- `Sentry.PlugCapture` in endpoint pipeline (before Router)
- `Sentry.PlugContext` in router pipeline (after `plug :accepts`)
- Captures unhandled exceptions with request context

### Sentry + Oban
- `Sentry.Integrations.Oban.handle_event/4` as telemetry handler
- Captures job failures with queue/worker/args context
- Attach in application.ex startup

### Configuration
- `config/config.exs`: Base Sentry config with `environment_name`, `included_environments: [:prod]`
- `config/runtime.exs`: Set `dsn` from `SENTRY_DSN` env var
- `config/test.exs`: No Sentry config needed (not in included_environments)
- Fly secret: `SENTRY_DSN` set via `fly secrets set`
