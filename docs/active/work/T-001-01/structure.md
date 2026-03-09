# T-001-01 Structure: Scaffold Phoenix

## Files Created (from `mix phx.new` + modifications)

### Root
- `mix.exs` — Project config with all Ash deps added
- `.formatter.exs` — With Ash DSL imports
- `.credo.exs` — Strict defaults

### config/
- `config/config.exs` — Base config (Phoenix, Ecto, esbuild, tailwind, mailer)
- `config/dev.exs` — Dev database, live reload, debug logging
- `config/test.exs` — Test database, async sandbox
- `config/prod.exs` — Production defaults (no secrets)
- `config/runtime.exs` — Runtime config reading env vars (DATABASE_URL, SECRET_KEY_BASE, PHX_HOST, operator config)

### lib/
- `lib/haul.ex` — Application module (starts Repo, Endpoint, Telemetry, Finch)
- `lib/haul_web.ex` — Web module macros (controller, live_view, component, router, etc.)
- `lib/haul/application.ex` — Application supervision tree
- `lib/haul/repo.ex` — Ecto Repo
- `lib/haul/mailer.ex` — Swoosh mailer
- `lib/haul_web/endpoint.ex` — Phoenix Endpoint
- `lib/haul_web/router.ex` — Router with default page route
- `lib/haul_web/telemetry.ex` — Telemetry supervisor
- `lib/haul_web/controllers/` — PageController, PageHTML, ErrorJSON, ErrorHTML
- `lib/haul_web/components/` — CoreComponents, Layouts
- `lib/haul_web/layouts/` — root.html.heex, app.html.heex

### assets/
- `assets/css/app.css` — Tailwind entry point
- `assets/js/app.js` — LiveView JS hooks, topbar
- `assets/vendor/topbar.js` — Vendored progress bar
- `assets/tailwind.config.js` — Tailwind config (if generated separately)

### priv/
- `priv/static/favicon.ico` — Default favicon
- `priv/static/robots.txt` — Default robots
- `priv/static/images/phoenix.png` — Default logo (will be replaced)
- `priv/repo/migrations/.gitkeep` — Empty migrations dir
- `priv/repo/seeds.exs` — Empty seeds file
- `priv/gettext/` — Gettext files

### test/
- `test/test_helper.exs` — ExUnit setup
- `test/support/conn_case.ex` — Connection test case
- `test/support/data_case.ex` — Data test case
- `test/haul_web/controllers/page_controller_test.exs` — Default page test
- `test/haul_web/controllers/error_json_test.exs` — Error JSON test
- `test/haul_web/controllers/error_html_test.exs` — Error HTML test

### Not created by this ticket (but dir structure supports them)
- `lib/haul/accounts/` — Future: AshAuthentication domain
- `lib/haul/operations/` — Future: Job, Quote, etc.
- `lib/haul_web/live/` — Future: LiveView modules
- `assets/css/print.css` — Future: Print stylesheet

## Files Modified

### `.gitignore`
- Keep existing content (already covers Phoenix patterns)
- Verify it includes all Phoenix-generated patterns, add any missing

## Module Boundaries

At this stage, module boundaries are minimal — standard Phoenix scaffolding:
- `Haul` — Application namespace
- `Haul.Repo` — Database interface
- `Haul.Mailer` — Email interface
- `HaulWeb` — Web layer namespace
- `HaulWeb.Endpoint` — HTTP endpoint
- `HaulWeb.Router` — Route definitions

No Ash domains or resources in this ticket. The structure supports adding them in `lib/haul/{domain_name}/` per the spec.

## Dependency Graph (mix.exs)

```
deps = [
  # Phoenix core
  {:phoenix, "~> 1.8"},
  {:phoenix_ecto, "~> 4.6"},
  {:ecto_sql, "~> 3.12"},
  {:postgrex, ">= 0.0.0"},
  {:phoenix_html, "~> 4.2"},
  {:phoenix_live_reload, "~> 1.6", only: :dev, runtime: false},
  {:phoenix_live_view, "~> 1.0"},
  {:phoenix_live_dashboard, "~> 0.8"},
  {:esbuild, "~> 0.9", runtime: Mix.env() == :dev},
  {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
  {:heroicons, github: "tailwindlabs/heroicons", tag: "v2.2.0", ...},
  {:swoosh, "~> 1.17"},
  {:finch, "~> 0.19"},
  {:telemetry_metrics, "~> 1.0"},
  {:telemetry_poller, "~> 1.0"},
  {:gettext, "~> 0.26"},
  {:jason, "~> 1.4"},
  {:dns_cluster, "~> 0.1"},
  {:bandit, "~> 1.6"},

  # Ash ecosystem
  {:ash, "~> 3.19"},
  {:ash_postgres, "~> 2.7"},
  {:ash_phoenix, "~> 2.3"},
  {:ash_authentication, "~> 4.13"},
  {:ash_state_machine, "~> 0.2.12"},
  {:ash_oban, "~> 0.7.2"},
  {:ash_double_entry, "~> 1.0"},
  {:ash_money, "~> 0.2.5"},
  {:ash_paper_trail, "~> 0.5.7"},
  {:ash_archival, "~> 2.0"},

  # Quality
  {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
  {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

  # Test
  {:ex_machina, "~> 2.8", only: :test},
]
```
