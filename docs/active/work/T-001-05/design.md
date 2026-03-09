# T-001-05 Design: Fly.io Deploy

## Decision 1: Health check approach

### Options

**A) Plug in endpoint before router** — Add a simple Plug at the top of the endpoint pipeline that intercepts `/healthz` and returns 200 before any session/CSRF/force_ssl processing.

**B) Route in router** — Add `/healthz` as a regular route in the router with a controller action.

**C) Bandit-level check** — Configure Bandit's built-in health check.

### Decision: Option A — Endpoint-level plug

- Health checks must bypass `force_ssl` (Fly's health checker hits the internal HTTP port directly, not through TLS)
- Endpoint plug runs before the router and before `force_ssl` (which is in prod.exs config, applied at endpoint level)
- Actually, `force_ssl` is configured via endpoint config, not as an explicit plug — it runs early. We need the health check to respond before force_ssl redirects.
- Best approach: add `/healthz` to the `force_ssl` exclude paths in `prod.exs`, then use a simple route. This keeps the health check in the router (visible, testable) while avoiding the redirect issue.

**Revised decision: Option B with force_ssl exclusion.** Add a route, exclude the path from force_ssl. Simpler, more conventional, testable.

## Decision 2: Health check depth

### Options

**A) Shallow (liveness)** — Return 200 with no DB check. Confirms BEAM is up and Phoenix is handling requests.

**B) Deep (readiness)** — Run a `SELECT 1` against the DB to confirm connectivity.

### Decision: Option A — Shallow liveness

- Fly health checks determine if a machine should receive traffic
- If DB is down, the app should still receive requests (to show error pages, not just 502)
- Neon has its own cold-start latency; a DB-dependent health check would cause false negatives
- Deep checks can be added later behind `/healthz?deep=true` if needed

## Decision 3: fly.toml configuration

Key settings:

```toml
app = "haul-page"
primary_region = "iad"

[http_service]
  internal_port = 4000
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 0

[http_service.checks]
  path = "/healthz"
  interval = "10s"
  timeout = "2s"
  grace_period = "10s"

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
```

- `iad` region: US East, good default, close to Neon's default `us-east-1`
- `auto_stop_machines = "stop"`: machines stop when idle (scale-to-zero)
- `min_machines_running = 0`: allows full scale-to-zero
- `shared-cpu-1x` with 256MB: smallest/cheapest VM, sufficient for a Phoenix app
- `force_https = true`: Fly handles TLS, redirects HTTP → HTTPS at edge

## Decision 4: SSL for Neon

Uncomment `ssl: true` in `config/runtime.exs` Ecto config. Neon requires SSL. No other changes needed — the DATABASE_URL from Neon already includes the correct connection params.

## Decision 5: CI deploy job fix

The deploy job has `needs: [test, quality, guardrails]` but guardrails only runs on PRs. Options:

**A) Remove guardrails from needs** — Deploy depends only on test + quality.
**B) Keep as-is** — Skipped jobs satisfy `needs`, so it works but is confusing.

### Decision: Option A

Remove `guardrails` from deploy's `needs`. It's misleading. Guardrails run on PRs; deploy runs on main push. They're independent. Deploy should gate on test + quality only.

## Decision 6: Pool size for Neon

Neon free tier allows ~100 connections. Default pool_size is 10, which is fine for a single machine. Keep the default. Scale-to-zero means we typically have 0 or 1 machines running.

## Rejected approaches

- **Multi-region deploy**: Unnecessary for single-operator app. Adds complexity and cost.
- **Dedicated CPU VM**: Overkill. shared-cpu-1x handles low-traffic Phoenix easily.
- **Custom health check plug in endpoint**: Over-engineered when force_ssl exclusion + route works.
- **DB-backed health check**: False negatives from Neon cold starts. Liveness is sufficient.
