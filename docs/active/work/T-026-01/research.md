# T-026-01 Research — native-postgres-switch

## Current Database Configuration

### Dev (`config/dev.exs`)
- Hostname: `localhost`, port: 5432 (default)
- Credentials: `postgres:postgres`
- Database: `haul_dev`
- Pool size: 10

### Test (`config/test.exs`)
- Same host/credentials as dev
- Database: `haul_test` (with optional `MIX_TEST_PARTITION` suffix)
- Pool: `Ecto.Adapters.SQL.Sandbox`
- Pool size: `System.schedulers_online() * 2`

### Production (`config/runtime.exs`)
- `DATABASE_URL` env var (required)
- SSL enabled, pool size 10 (configurable via `POOL_SIZE`)
- Currently Neon Postgres (serverless)

**Key finding: No config changes needed.** Both dev and test already target `localhost:5432` with `postgres:postgres`. The switch is purely infrastructure.

## Current Docker Setup

### What exists
- **Dockerfile** — Multi-stage build for Fly.io deployment (stays, not affected)
- **.dockerignore** — For the production Dockerfile (stays)
- **No docker-compose.yml** — The `haul-pg` container was started manually
- **CI uses `postgres:16`** as a GitHub Actions service container (separate from local dev)

### Footprint (from report)
- Docker Desktop VM: 4.7 GB RSS (`com.docker.krun`)
- Docker total overhead: ~5.2 GB
- `haul-pg` container: 1.44 GB memory, 36.8 GB block writes
- App (BEAM + watchers): ~270 MB total

### Docker references in codebase
- `Dockerfile` — production build only, NOT for local Postgres
- `.dockerignore` — production build only
- CI workflow `postgres:16` service — GitHub Actions, not local dev
- Footprint report — documentation
- No code or config references to `haul-pg` container name

## Tool Version Management

### Current `mise.toml`
```toml
[tools]
erlang = "28"
elixir = "1.19"
```
- Only Erlang and Elixir pinned
- Comment says to keep in sync with CI and Dockerfile
- **Postgres not pinned** — this is the gap

### mise Postgres availability
- `mise` has a postgres plugin via `mise-plugins/mise-postgres`
- Available versions: 17.9, 18.0–18.3
- `mise install postgres@18` would install the server
- mise can manage `PGDATA`, `initdb`, `pg_ctl start/stop`

### Current Postgres on host
- `libpq` 18.3 installed via Homebrew (client only: `psql`, `pg_dump`, etc.)
- `pg_ctl` 18.3 available (from libpq, but can't start server without full install)
- **Full `postgresql@18` is NOT installed** — `brew info` shows "Not installed"
- No Postgres data directory exists at expected locations

## Repo Module (`lib/haul/repo.ex`)

```elixir
defmodule Haul.Repo do
  use AshPostgres.Repo, otp_app: :haul

  def installed_extensions do
    ["uuid-ossp", "citext", "ash-functions"]
  end

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end
end
```

- `min_pg_version` is 16.0.0 — PG 18 satisfies this
- Extensions needed: `uuid-ossp`, `citext`, `ash-functions`
  - `uuid-ossp` and `citext` are standard contrib extensions, available in all PG versions
  - `ash-functions` is installed by Ash migrations (custom functions)

## Dev Workflow (`just dev` / `.just/system.just`)

The `_dev` recipe:
1. Singleton guard (checks if port 4000 already listening)
2. `mix deps.get` if needed
3. `mix ecto.create` + `mix ecto.migrate`
4. `mix phx.server` in background

The `_setup` recipe:
1. Checks for `elixir` and `psql` on PATH
2. `mix deps.get`, `mix compile`, `mix ecto.setup`, `mix assets.setup`

**Neither recipe starts or manages Postgres.** They assume it's already running. This is fine — mise-managed Postgres would need a separate start step.

## Ash Schema-per-Tenant on PG 18

Ash multi-tenancy uses these DDL operations:
- `CREATE SCHEMA "tenant_xxx"` — creates per-tenant schema
- `SET search_path TO "tenant_xxx"` — switches context
- `DROP SCHEMA "tenant_xxx" CASCADE` — teardown
- Standard migrations run per-schema

PG 18 release notes (key changes from 16):
- No breaking changes to schema DDL
- `synchronous_commit` default unchanged (`on`)
- `max_connections` default unchanged (`100`)
- `shared_buffers` default unchanged (`128MB`)
- New: virtual generated columns, JSON improvements, COPY improvements
- No SQL syntax removals that would affect Ash-generated queries

## CI Configuration

```yaml
services:
  postgres:
    image: postgres:16
```

CI runs PG 16. Local dev will run PG 18. This version mismatch is acceptable:
- PG 18 is backward-compatible with PG 16 SQL
- Ash-generated queries use standard SQL
- The only risk: PG 18-specific features used locally wouldn't work in CI
- Since we're not adding PG 18 features, just verifying compatibility, this is fine

## Documents That Reference Docker/Postgres

| File | Content | Needs update? |
|------|---------|---------------|
| `README.md` | "Requires Postgres running locally" | Clarify: mise-managed |
| `CONTRIBUTING.md` | "Requires Postgres" | Add mise setup instructions |
| `DEPLOYMENT.md` | Docker for Fly.io only | No change needed |
| `.just/system.just` `_llm` | "Postgres (Neon, serverless)" | No change (describes prod) |
| `.just/system.just` `_setup` | Checks for `psql` | May need `pg_isready` check |
| `docs/active/work/footprint-report-2026-03-09.md` | Docker analysis | Historical, no change |

## Summary of Findings

1. **Config is already correct** — `localhost:5432`, `postgres:postgres`
2. **No Postgres server installed** — only `libpq` client tools
3. **mise can manage Postgres** — plugin available, 18.3 latest
4. **Dockerfile is production-only** — unaffected by this change
5. **CI uses PG 16** — acceptable version delta
6. **No code references Docker** — only the footprint report mentions `haul-pg`
7. **Ash extensions are standard** — no PG 18 compatibility concerns
8. **Dev recipes don't manage Postgres lifecycle** — need to document manual start or add recipe
