# T-011-03 Research: Monitoring Setup

## Current State

### Error Tracking
- **No error tracking dependency** in mix.exs — no Sentry, Honeybadger, etc.
- Errors logged to stdout via Elixir Logger — not aggregated or alerted
- Logger metadata includes `request_id` (from Plug.RequestId)
- Logger levels: `:info` (prod), `:warning` (test), debug (dev)
- 6 files use Logger explicitly (webhook controller, places adapter, SMS sandbox)

### Health Check
- `/healthz` endpoint at `lib/haul_web/controllers/health_controller.ex`
- Returns `200 "ok"` unconditionally — no depth checks (no DB ping)
- Fly health check configured: 10s interval, 2s timeout, 10s grace period
- Route defined in router.ex outside any scope/pipeline

### Telemetry
- `HaulWeb.Telemetry` in supervision tree collects Phoenix/Ecto/VM metrics
- No reporters configured — metrics collected but not exported
- ConsoleReporter commented out in telemetry.ex

### Error Handling
- `ErrorHTML` and `ErrorJSON` modules render errors via Phoenix defaults
- No custom error middleware or exception tracking plug
- Endpoint pipeline: RequestId → Telemetry → Parsers → Router

### Configuration Pattern
- Adapter-based: behaviour module + sandbox adapter (dev/test) + real adapter (prod)
- Runtime switching via env vars in `config/runtime.exs`
- Examples: Payments (Stripe), SMS (Twilio), Places (Google)
- Pattern: `if env_var = System.get_env("KEY") do config :haul, :adapter, RealModule end`

### Deployment
- Fly.io: `haul-page` app, `iad` region, `shared-cpu-1x` 256MB
- Auto-scales to zero. Force HTTPS with HSTS
- CI: test + quality + guardrails + deploy pipeline
- No post-deploy smoke test or monitoring verification

### Key Files
- `mix.exs` — dependencies
- `config/config.exs` — base config (sandbox adapters)
- `config/runtime.exs` — production secrets from env vars
- `config/prod.exs` — compile-time prod settings
- `lib/haul_web/endpoint.ex` — plug pipeline
- `lib/haul_web/controllers/health_controller.ex` — health check
- `lib/haul/application.ex` — supervision tree
- `lib/haul_web/telemetry.ex` — metrics collection
- `fly.toml` — Fly deployment config

### External Service Pattern (to follow)
1. Behaviour module defines callbacks
2. Sandbox adapter for dev/test (logs, returns canned data)
3. Real adapter wraps external SDK
4. Config switches adapter based on env var presence
5. Test config always uses sandbox
