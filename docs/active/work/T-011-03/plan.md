# T-011-03 Plan: Monitoring Setup

## Step 1: Add Sentry dependency
- Add `{:sentry, "~> 10.0"}` and `{:hackney, "~> 1.8"}` to mix.exs
- Run `mix deps.get`
- Verify compilation: `mix compile`

## Step 2: Configure Sentry
- Add base config to `config/config.exs`
- Add runtime DSN loading to `config/runtime.exs`
- Add explicit `dsn: nil` to `config/test.exs`

## Step 3: Add Plug integration
- Add `plug Sentry.PlugCapture` to endpoint.ex (before Router)
- Add `plug Sentry.PlugContext` to browser pipeline in router.ex

## Step 4: Add Oban integration
- Attach `Sentry.Integrations.Oban.handle_event/4` telemetry handler in application.ex

## Step 5: Add test error endpoint
- Create `lib/haul_web/controllers/debug_controller.ex`
- Add dev-only route `GET /debug/error` in router.ex

## Step 6: Write tests
- Test that `/debug/error` raises in test (assert_error_sent)
- Test that Sentry config is correct (dsn nil in test)
- Verify existing tests still pass: `mix test`

## Step 7: Verify
- Run full test suite
- Run `mix compile --warnings-as-errors`
- Run `mix format`

## Testing Strategy
- Unit test: DebugController raises RuntimeError
- Config test: Verify Sentry DSN is nil in test env
- Regression: Full `mix test` passes (no Sentry side effects in test)
- Manual: In dev, visit `/debug/error` to see the error page
