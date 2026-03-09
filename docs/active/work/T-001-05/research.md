# T-001-05 Research: Fly.io Deploy

## Ticket scope

Configure Fly.io app + Neon Postgres. Deploy scaffolded app at a public URL. Add CI deploy job.

## What exists

### Dockerfile (complete, from T-001-04)

- Three-stage build: deps → build → runtime
- Based on `hexpm/elixir` builder, `debian:bookworm-slim` runner
- Runs `mix assets.deploy` and `mix release`
- CMD is `bin/migrate_and_start`
- Version pins: Elixir 1.19.3, OTP 28.4

### Release scripts (`rel/overlays/bin/`)

- `migrate` — runs `Haul.Release.migrate` via eval
- `server` — sets `PHX_SERVER=true` and starts the release
- `migrate_and_start` — runs migrate then starts server (used as CMD)
- `migrate.bat` / `server.bat` — Windows equivalents (unused for deploy)

### Release module (`lib/haul/release.ex`)

- `Haul.Release.migrate/0` — loads app, runs all pending Ecto migrations
- Uses `Ecto.Migrator.with_repo/2` pattern
- Starts SSL before migration (needed for Neon)

### Runtime config (`config/runtime.exs`)

- Reads `DATABASE_URL`, `SECRET_KEY_BASE`, `PHX_HOST`, `PORT`, `PHX_SERVER`
- Reads `POOL_SIZE` (default 10), `ECTO_IPV6`, `DNS_CLUSTER_QUERY`
- Operator config overrides via `OPERATOR_*` env vars
- SSL for Ecto is commented out (`# ssl: true`) — **Neon requires SSL**

### Prod config (`config/prod.exs`)

- `force_ssl` with `rewrite_on: [:x_forwarded_proto]` — correct for Fly's proxy
- Excludes localhost/127.0.0.1 from force_ssl
- Static manifest enabled
- Logger level `:info`

### CI pipeline (`.github/workflows/ci.yml`)

- Jobs: test, quality, guardrails (PR only), deploy
- Deploy job already exists with correct structure:
  - `needs: [test, quality, guardrails]`
  - Runs only on `main` push
  - Uses `superfly/flyctl-actions/setup-flyctl@master`
  - Runs `flyctl deploy --remote-only`
  - Reads `FLY_API_TOKEN` from secrets
- **Issue**: Deploy `needs` includes `guardrails` but guardrails only runs on PRs (`if: github.event_name == 'pull_request'`). Since deploy runs on push to main, guardrails will be skipped — a skipped job satisfies `needs` so this works, but the dependency is misleading.

### Router (`lib/haul_web/router.ex`)

- Single route: `GET /` → `PageController.home`
- No `/healthz` endpoint exists yet — **must add**

### Endpoint (`lib/haul_web/endpoint.ex`)

- Standard Phoenix endpoint with Plug.Static, sessions, CSRF
- No health check bypass

### What does NOT exist

1. **`fly.toml`** — must create
2. **Health check endpoint (`/healthz`)** — must add
3. **SSL enabled for Ecto/Neon** — `ssl: true` is commented out in runtime.exs

## Key constraints

### Neon Postgres

- Requires SSL connections (non-negotiable)
- Connection pooling via PgBouncer built-in — use `?sslmode=require` in URL or set `ssl: true` in Ecto config
- Scales to zero; first connection after idle may take ~500ms cold start
- Free tier: 0.5 GiB storage, 190 compute hours/month

### Fly.io

- Single shared-CPU VM target (~$4-8/mo per spec)
- `auto_stop_machines` for scale-to-zero
- Health check on HTTP endpoint to determine readiness
- TLS termination at edge, app receives HTTP with `x-forwarded-proto`
- Deploy via `flyctl deploy --remote-only` (builds Docker image on Fly's remote builder)
- Secrets set via `fly secrets set KEY=value`
- Region: single region deployment (spec says cost-optimize)

### Health check design

- Must respond quickly (no DB dependency for liveness)
- Path: `/healthz` per acceptance criteria
- Should bypass the full Plug pipeline (no CSRF, no session, no force_ssl redirect)
- Prod config excludes health check from force_ssl — commented out (`# paths: ["/health"]`)

## Files to modify

| File | Action | Purpose |
|------|--------|---------|
| `fly.toml` | Create | Fly.io app configuration |
| `lib/haul_web/router.ex` | Modify | Add `/healthz` route |
| `lib/haul_web/endpoint.ex` | Modify | Health check before plug pipeline |
| `config/runtime.exs` | Modify | Enable SSL for Neon |
| `config/prod.exs` | Modify | Exclude `/healthz` from force_ssl |
| `.github/workflows/ci.yml` | Modify | Fix guardrails dependency in deploy |

## Open questions

1. App name: `haul-page` on Fly? (spec says "haul-page.fly.dev or similar")
2. Region selection: `iad` (US East) is closest to Neon's default region
3. Pool size: Neon free tier has connection limits — 10 may be fine, but 5 is safer with scale-to-zero
4. Should the health check hit the DB (readiness) or just confirm the app is up (liveness)?
