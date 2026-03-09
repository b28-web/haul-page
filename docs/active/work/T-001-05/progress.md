# T-001-05 Progress: Fly.io Deploy

## Completed

- [x] Step 1: Created `lib/haul_web/controllers/health_controller.ex` — returns 200 "ok" text/plain
- [x] Step 2: Created `test/haul_web/controllers/health_controller_test.exs` — 1 test, passing
- [x] Step 3: Added `/healthz` route to router (pipeline-less scope)
- [x] Step 4: Updated `config/prod.exs` — added `/healthz` to force_ssl exclude paths
- [x] Step 5: Enabled `ssl: true` in `config/runtime.exs` for Neon Postgres
- [x] Step 6: Created `fly.toml` — iad region, shared-cpu-1x, 256MB, auto-stop, health check
- [x] Step 7: Fixed CI deploy job — removed guardrails from needs (only runs on PRs)
- [x] Step 8: Full test suite passes (12 tests, 0 failures)

## Deviations from plan

None. All steps executed as planned.

## Notes

- Pre-existing formatting issues exist in `config/config.exs`, `home.html.heex`, and `page_controller_test.exs` — not introduced by this ticket, not fixed (out of scope)
- Fly app creation (`fly apps create haul-page`) and secrets setup (`fly secrets set DATABASE_URL=... SECRET_KEY_BASE=...`) must be done manually before first deploy
- `fly.toml` includes `PHX_HOST = "haul-page.fly.dev"` as env var — update if custom domain is configured later
