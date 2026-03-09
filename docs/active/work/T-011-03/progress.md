# T-011-03 Progress: Monitoring Setup

## Completed Steps

### Step 1: Add Sentry dependency ✓
- Added `{:sentry, "~> 12.0"}` to mix.exs
- `mix deps.get` pulled sentry 12.0.2 + nimble_ownership 1.0.2
- Finch already present as transitive dep — no extra HTTP client needed

### Step 2: Configure Sentry ✓
- Base config in config.exs: environment_name, source_code_context, root paths
- Runtime DSN loading in runtime.exs: `SENTRY_DSN` env var
- No explicit test.exs override needed — DSN nil by default

### Step 3: Add Plug integration ✓
- Added `plug Sentry.PlugContext` to endpoint.ex after Plug.Session
- Note: `Sentry.PlugCapture` is Cowboy-only (`use` macro). We use Bandit, so only PlugContext needed.

### Step 4: Add Logger handler ✓
- Added `:logger.add_handler(:sentry_handler, Sentry.LoggerHandler, ...)` in application.ex start/2
- Captures Logger.error and OTP crash reports automatically
- Note: Sentry v12 does NOT have a `child_spec/1` — removed `{Sentry, []}` from supervision tree

### Step 5: Add test error endpoint ✓
- Created DebugController with raise action
- Routed at `/dev/sentry-test` (dev-only, behind `:dev_routes` config)

### Step 6: Write tests ✓
- DebugController test: verifies route is not accessible in test env (404)
- SentryConfig test: verifies DSN nil, environment_name :test, source_code_context enabled
- Full suite: 212 tests, 0 failures (up from 208)

### Step 7: Verify ✓
- `mix compile --warnings-as-errors` — clean
- `mix format` — clean
- `mix test` — 212 tests, 0 failures

## Deviations from Plan
- **No Oban telemetry handler**: Sentry v12 handles Oban integration via config, not explicit telemetry attachment. The Logger handler already captures Oban job failures via OTP crash reports.
- **No Sentry in supervision tree**: v12 doesn't need a supervised process — it sends events via Finch directly.
- **PlugCapture removed**: Only needed for Cowboy adapter. Bandit users just need PlugContext.
