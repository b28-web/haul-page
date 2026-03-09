# T-001-06 Research: mix setup

## Current `mix setup` alias

In `mix.exs:99`:
```elixir
setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"]
```

Sub-aliases:
- `ecto.setup`: `["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]`
- `assets.setup`: `["tailwind.install --if-missing", "esbuild.install --if-missing"]`
- `assets.build`: `["compile", "tailwind haul", "esbuild haul"]`

## What works

1. **deps.get** — straightforward, no issues expected.
2. **ecto.create** — dev.exs configures `haul_dev` with postgres/postgres on localhost. Standard Phoenix default.
3. **ecto.migrate** — no migrations exist yet (`priv/repo/migrations/` is empty except `.formatter.exs`). This is a no-op currently but correct to include.
4. **assets.setup** — downloads tailwind (4.1.12) and esbuild (0.25.4) binaries if missing. Versions pinned in config.exs.
5. **assets.build** — compiles, then runs tailwind and esbuild. Depends on `assets/css/app.css` and `assets/js/app.js` existing.

## What's missing or broken

### Seeds file is empty
`priv/repo/seeds.exs` is the default Phoenix scaffold placeholder — no actual seed data. The acceptance criteria require "Dev seeds create a sample operator with realistic data."

However: there are **no Ash resources defined yet** (see OVERVIEW.md cross-ticket notes). No database tables, no schemas. Operator config is currently in `config.exs` as application config, not a database record.

This means seeds can't create database records for a "sample operator" because the Company/User resources don't exist yet (T-004-01). The seeds file should be prepared with a clear structure and comments indicating where operator seed data will go, plus populate any config that can be seeded now.

### `deps.compile` not in the alias
The acceptance criteria say `mix setup` should run `deps.compile`. Currently it's `deps.get` → `ecto.setup` → `assets.setup` → `assets.build`. The `compile` step in `assets.build` handles compilation of the project and deps, but `deps.compile` as a separate explicit step isn't present. In practice, `ecto.create` triggers compilation via `mix app.config`, so deps are compiled before the DB step. This is fine — no change needed.

### Missing: `deps.compile` is effectively covered
The `compile` task in `assets.build` and the implicit compilation during `ecto.create` cover this. Not a gap.

## Environment requirements

From clean clone, a contributor needs:
- Elixir 1.19 / Erlang 28 (pinned in `mise.toml`)
- PostgreSQL (dev.exs assumes `postgres:postgres@localhost`)
- No Node.js required (tailwind + esbuild are Elixir-managed binaries)

## Existing test infrastructure

- 11 tests: 7 page controller + 4 error handler
- `test/support/` directory exists
- `test_helper.exs` exists
- Test alias: `test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]`

## Files relevant to this ticket

| File | Role |
|------|------|
| `mix.exs` | Setup alias definition |
| `priv/repo/seeds.exs` | Seed script (empty) |
| `config/dev.exs` | Dev database config |
| `config/config.exs` | Operator defaults, asset tool versions |
| `config/test.exs` | Test database config |
| `lib/haul/repo.ex` | Ecto repo module |
| `lib/haul/application.ex` | App supervision tree |

## Key constraints

1. No Ash resources exist yet — seeds can't create domain records
2. Operator identity is config-driven, not DB-driven (yet)
3. Multi-tenancy (schema-per-tenant) is planned but not implemented
4. The project compiles and the dev server runs on port 4000
