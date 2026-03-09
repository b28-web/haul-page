# T-001-05 Structure: Fly.io Deploy

## Files to create

### `fly.toml`

Root-level Fly.io configuration file. Contains:
- App name, primary region
- HTTP service config (port, HTTPS, auto-stop, health check)
- VM sizing

### `lib/haul_web/controllers/health_controller.ex`

Minimal controller with single `index/2` action. Returns `200 OK` with `text/plain` body "ok". No layout, no HTML.

### `test/haul_web/controllers/health_controller_test.exs`

Tests that `GET /healthz` returns 200 with body "ok".

## Files to modify

### `lib/haul_web/router.ex`

Add a new scope outside the `:browser` pipeline for the health check:

```
scope "/" do
  get "/healthz", HaulWeb.HealthController, :index
end
```

No pipeline — raw GET with no session/CSRF overhead.

### `config/prod.exs`

Uncomment/add `/healthz` to `force_ssl` exclude paths:

```elixir
force_ssl: [
  rewrite_on: [:x_forwarded_proto],
  exclude: [
    paths: ["/healthz"],
    hosts: ["localhost", "127.0.0.1"]
  ]
]
```

### `config/runtime.exs`

Enable SSL for Ecto in production:

```elixir
config :haul, Haul.Repo,
  ssl: true,
  url: database_url,
  ...
```

### `.github/workflows/ci.yml`

Change deploy job's `needs` from `[test, quality, guardrails]` to `[test, quality]`.

## Files NOT modified

- `Dockerfile` — already correct from T-001-04
- `rel/overlays/bin/*` — already correct
- `lib/haul/release.ex` — already correct (SSL started before migrate)
- `mix.exs` — no new deps needed
- `.dockerignore` — already correct
- `lib/haul_web/endpoint.ex` — no changes needed; force_ssl exclusion handles health check

## Module boundaries

- `HaulWeb.HealthController` is a plain Phoenix controller, not a LiveView
- It has no dependencies on any domain logic or Ecto
- It sits in the `HaulWeb` namespace alongside other controllers

## Ordering

1. Health controller + test (pure code, no infra)
2. Router change (depends on controller)
3. Config changes (runtime.exs SSL, prod.exs force_ssl exclusion)
4. fly.toml (independent of code changes)
5. CI fix (independent)

All code changes should be in a single commit. fly.toml in same or separate commit.
