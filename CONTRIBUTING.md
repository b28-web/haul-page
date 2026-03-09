# Contributing

## Setup

```bash
# 1. Install toolchain
mise install                        # Pins Elixir 1.19 + Erlang/OTP 28

# 2. Install deps and set up database
mix setup                           # Or: just dev (does this automatically)

# 3. Start dev server
mix phx.server                      # http://localhost:4000
```

Requires Postgres. If you don't have it locally, point `DATABASE_URL` at a Neon instance.

## Development workflow

```bash
just dev                            # Start server (auto-fetches deps, migrates)
mix test                            # Run tests
mix format                          # Format code
mix credo --strict                  # Lint
mix dialyzer                        # Type checking
```

## Project structure

```
lib/haul/                           # Ash domains + resources
lib/haul_web/                       # Phoenix web layer
assets/css/                         # Tailwind CSS
assets/js/                          # LiveView hooks (minimal)
docs/knowledge/                     # Specs, design decisions
docs/active/tickets/                # Implementation tickets (lisa DAG)
docs/active/epics/                  # Ongoing health goals
docs/active/stories/                # Feature stories
```

## Task management

Tickets live in `docs/active/tickets/` as markdown with YAML frontmatter. They form a DAG managed by [lisa](https://github.com/anthropics/lisa).

```bash
just status                         # See DAG, waves, what's ready
lisa validate                       # Check for cycles or missing deps
just work                           # Launch agent swarm (2 concurrent tickets)
```

## Tickets follow the RDSPI workflow

Every ticket passes through six phases: **Research → Design → Structure → Plan → Implement → Review**. Each phase produces a ~200 line artifact in `docs/active/work/{ticket-id}/`. See [docs/knowledge/rdspi-workflow.md](docs/knowledge/rdspi-workflow.md).

## Code conventions

- **Ash resources are the source of truth.** Business logic lives in resource definitions, not controllers or LiveViews.
- **Named actions.** Every Ash action has an intent-driven name (`:create_from_online_booking`, not `:create`).
- **No umbrella.** Single Phoenix app. Ash domains provide modularity.
- **No separate frontend build.** Tailwind + esbuild via Mix tasks. No node_modules.
- **Dark theme default.** Grayscale palette. Oswald for headings, Source Sans 3 for body.
- **Operator config via env vars.** Business name, phone, colors — all runtime config, not code.

## CI

GitHub Actions runs on every PR:

1. **test** — `mix test` against Postgres 16
2. **quality** — `mix format --check-formatted` + `mix credo --strict` + `mix dialyzer`

Both must pass before merge. Deploy to Fly.io triggers automatically on push to `main`.
