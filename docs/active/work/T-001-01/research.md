# T-001-01 Research: Scaffold Phoenix

## Current State of the Repo

The repo contains only documentation, CI config, and tooling — no Elixir code exists yet.

### Existing Files (relevant to scaffolding)
- `CLAUDE.md` — project conventions, Ash patterns, directory layout expectations
- `docs/knowledge/specification.md` — full spec defining monorepo structure, stack, deps
- `.github/workflows/ci.yml` — CI pipeline expecting `mix compile`, `mix test`, `mix format`, `mix credo`
- `.gitignore` — already configured for Phoenix (`/_build/`, `/deps/`, `/priv/static/assets/`, etc.)
- `justfile` + `.just/system.just` — dev/deploy/quality recipes assuming `mix` commands exist
- `.githooks/` — pre-commit hooks directory (empty or minimal)

### What Needs to Exist After This Ticket
- `mix.exs` with all deps
- `config/` directory (config.exs, dev.exs, test.exs, prod.exs, runtime.exs)
- `lib/haul.ex`, `lib/haul_web.ex`
- `lib/haul_web/` (endpoint, router, telemetry, controllers, layouts, components)
- `lib/haul/` (application module, repo, mailer)
- `assets/` (css/app.css, js/app.js, vendor/)
- `priv/` (static assets, repo migrations, gettext)
- `test/` (test_helper.exs, support, basic tests)
- `.formatter.exs` with Ash DSL imports
- `.credo.exs` with strict defaults

## Environment

- Elixir 1.19.5, OTP 28
- Phoenix installer v1.8.5 (`mix phx.new`)
- No `.tool-versions` or `.mise.toml` — relying on system Elixir

## Dependency Landscape

### Core Ash Ecosystem (from ticket AC)
| Package | Latest Config | Purpose |
|---------|--------------|---------|
| ash | ~> 3.19 | Core framework |
| ash_postgres | ~> 2.7 | Postgres data layer |
| ash_phoenix | ~> 2.3 | Phoenix integration (forms, errors) |
| ash_authentication | ~> 4.13 | User auth (magic link, password) |
| ash_state_machine | ~> 0.2.12 | Job state transitions |
| ash_oban | ~> 0.7.2 | Background jobs via Oban |
| ash_double_entry | ~> 1.0 | Ledger/billing |
| ash_money | ~> 0.2.5 | Money type |
| ash_paper_trail | ~> 0.5.7 | Audit trail |
| ash_archival | ~> 2.0 | Soft deletes |

### Quality/Test deps
| Package | Latest Config | Purpose |
|---------|--------------|---------|
| credo | ~> 1.7 | Static analysis |
| dialyxir | ~> 1.4 | Type checking |
| ex_machina | ~> 2.8 | Test factories |

### Implicit deps (pulled by Phoenix 1.8)
- phoenix, phoenix_html, phoenix_live_view, phoenix_live_reload
- ecto, ecto_sql, postgrex
- telemetry, telemetry_metrics, telemetry_poller
- jason, plug_cowboy/bandit
- esbuild, tailwind (Mix tasks, no Node)
- swoosh (mailer), finch (HTTP client)
- gettext, dns_cluster, heroicons

## Constraints and Risks

1. **Ash 3.x formatter config** — Ash DSL requires import entries in `.formatter.exs` for each Ash extension. Missing imports cause `mix format` to break DSL blocks. Must configure upfront.

2. **`mix phx.new` in existing directory** — The repo already has files (.gitignore, README.md, CLAUDE.md, docs/). Running `mix phx.new` in the repo root will ask to overwrite existing files. Need to handle this carefully — either generate into a temp dir and copy, or use `--no-git --no-install` flags and merge.

3. **App name** — Spec says the app is named `haul`. Phoenix generator: `mix phx.new . --app haul` generates in current directory.

4. **CI compatibility** — CI expects `mix compile --warnings-as-errors`. Ash deps may produce compile warnings. Need to verify zero-warning compilation.

5. **No database needed yet** — This ticket only scaffolds. No Ash resources, no migrations. But Ecto/Repo must be configured for future tickets.

6. **Elixir 1.19 / OTP 28** — Very recent. All deps should be compatible but worth verifying during compilation.

## Key Decisions for Design Phase

- How to handle `mix phx.new` in a non-empty directory
- Whether to use Bandit or Cowboy as the HTTP server (Phoenix 1.8 default)
- How to structure `.formatter.exs` for Ash extensions
- Whether to add all Ash deps now or only the ones immediately needed
