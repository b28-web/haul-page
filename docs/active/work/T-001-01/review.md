# T-001-01 Review: Scaffold Phoenix

## Summary

Phoenix 1.8.5 app scaffolded with all Ash ecosystem dependencies. The project compiles with zero warnings, passes all tests, and satisfies every acceptance criterion.

## Acceptance Criteria Verification

| Criterion | Status | Notes |
|-----------|--------|-------|
| `mix phx.new` generates app named `haul` | ✓ | Generated via `mix phx.new /tmp/haul --app haul --module Haul` then copied |
| mix.exs includes Ash core deps | ✓ | All 10: ash, ash_postgres, ash_phoenix, ash_authentication, ash_state_machine, ash_oban, ash_double_entry, ash_money, ash_paper_trail, ash_archival |
| Includes credo, dialyxir, ex_machina | ✓ | credo + dialyxir in :dev/:test; ex_machina in :test only |
| `mix deps.get && mix compile` succeeds with zero warnings | ✓ | `mix compile --warnings-as-errors` passes |
| `.formatter.exs` configured for Ash DSL imports | ✓ | All 10 Ash packages + ecto + ecto_sql + phoenix in import_deps |
| `.credo.exs` generated with strict defaults | ✓ | Generated via `mix credo gen.config`; CI runs `--strict` flag |

## Files Created

### Application code (from Phoenix generator + modifications)
- `mix.exs` — Project config with all deps
- `.formatter.exs` — Ash DSL imports configured
- `.credo.exs` — Credo config
- `config/` — config.exs, dev.exs, test.exs, prod.exs, runtime.exs
- `lib/haul.ex` — Top-level module
- `lib/haul/application.ex` — OTP application
- `lib/haul/repo.ex` — Ecto Repo
- `lib/haul/mailer.ex` — Swoosh mailer
- `lib/haul/cldr.ex` — CLDR backend (required by ex_money/ash_money)
- `lib/haul_web.ex` — Web module macros
- `lib/haul_web/` — Endpoint, Router, Telemetry, Controllers, Components, Layouts
- `assets/` — CSS (Tailwind), JS (LiveView hooks), vendor libs
- `priv/` — Static assets, gettext, repo migrations dir, seeds
- `test/` — test_helper, support (conn_case, data_case), controller tests
- `mix.lock` — Locked dependency versions

### Work artifacts
- `docs/active/work/T-001-01/research.md`
- `docs/active/work/T-001-01/design.md`
- `docs/active/work/T-001-01/structure.md`
- `docs/active/work/T-001-01/plan.md`
- `docs/active/work/T-001-01/progress.md`
- `docs/active/work/T-001-01/review.md` (this file)

## Files Modified

- None. All existing repo files (CLAUDE.md, .gitignore, README.md, docs/) preserved as-is.

## Test Coverage

- **5 tests, 0 failures** — Default Phoenix test suite:
  - `PageControllerTest` — GET "/" returns 200
  - `ErrorHTMLTest` — 404/500 HTML rendering
  - `ErrorJSONTest` — 404/500 JSON rendering
- No new tests needed — this ticket is pure scaffolding. Test infrastructure (conn_case, data_case with sandbox) is set up for future tickets.

## Deviations from Plan

1. **Haul.Cldr module added** — `ash_money` depends on `ex_money` which requires a CLDR backend at application start. Created `lib/haul/cldr.ex` and added `config :ex_money, default_cldr_backend: Haul.Cldr` to config.exs. This is a hard runtime requirement, not optional.

2. **Credo fixes in generated code** — Phoenix 1.8 generator produces code with 4 credo strict violations. Fixed:
   - Alphabetized aliases in `lib/haul_web.ex`
   - Added `alias Phoenix.HTML.Form` in `core_components.ex`
   - Aliased `Ecto.Adapters.SQL.Sandbox` in `test/support/data_case.ex`

## Open Concerns

1. **Upstream dep warnings** — `ash_postgres` emits 3 warnings about missing `Igniter.Inflex` and `Owl.IO` modules (optional deps for its resource generator). These are compile-time warnings in the dep itself, not in our code, and don't affect `--warnings-as-errors` for the haul app. They'll resolve when ash_postgres releases a fix.

2. **ash_state_machine deprecation warning** — `AshStateMachine.Transition` missing `__spark_metadata__` field. Upstream issue, will be fixed in a future release.

3. **No Oban config** — `ash_oban` is a dependency but Oban itself is not configured (no queue config, no migrations). This is intentional — Oban config comes when the first background job is defined in a later ticket.

4. **Database required for tests** — Tests need a running Postgres instance. Docker Postgres was used locally (`postgres:16` on port 5432). CI already has Postgres as a service. Local dev should document this requirement.

5. **Phoenix 1.8 uses daisyUI** — The generator now includes daisyUI (Tailwind plugin) vendor files. The spec calls for pure Tailwind with custom dark theme. DaisyUI components may need to be removed or replaced in a future ticket focused on styling.

## No Critical Issues

All acceptance criteria met. The project is ready for downstream tickets to build on.
