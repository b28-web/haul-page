# T-011-03 Structure: Monitoring Setup

## Files Modified

### `mix.exs`
- Add `{:sentry, "~> 10.0"}` to deps
- Add `{:hackney, "~> 1.8"}` to deps (Sentry's HTTP client)

### `config/config.exs`
- Add Sentry base configuration block:
  - `dsn: nil` (set at runtime)
  - `environment_name: config_env()`
  - `included_environments: [:prod]`
  - `enable_source_code_context: true`
  - `root_source_code_paths: [File.cwd!()]`

### `config/runtime.exs`
- Add Sentry DSN block: `if sentry_dsn = System.get_env("SENTRY_DSN")` → set `config :sentry, dsn: sentry_dsn`

### `lib/haul_web/endpoint.ex`
- Add `plug Sentry.PlugCapture` before `plug HaulWeb.Router`

### `lib/haul_web/router.ex`
- Add `plug Sentry.PlugContext` in `:browser` pipeline
- Add dev-only scope with `/debug/error` test endpoint

### `lib/haul_web/controllers/debug_controller.ex` (NEW)
- Simple controller with `error/2` action that raises RuntimeError
- Only routed in dev via `if Mix.env() == :dev` guard in router

### `lib/haul/application.ex`
- Attach Sentry Oban telemetry handler in `start/2`

### `config/test.exs`
- Add `config :sentry, dsn: nil` to ensure Sentry is explicitly disabled in test

## Files NOT Changed
- `fly.toml` — health check config stays as-is
- `lib/haul_web/controllers/health_controller.ex` — no depth check changes
- `.github/workflows/ci.yml` — no CI changes needed
- No new behaviour/adapter modules — Sentry configured directly

## Module Boundaries
- Sentry is a cross-cutting concern, not a domain module
- Integration is via config + plugs + telemetry — no custom wrapper modules
- DebugController is a thin dev-only helper, not part of the domain
