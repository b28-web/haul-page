# T-001-05 Plan: Fly.io Deploy

## Step 1: Add health check controller

Create `lib/haul_web/controllers/health_controller.ex`:
- Single `index/2` action
- Returns `text/plain` "ok" with 200 status
- No layout rendering

**Verify**: File compiles.

## Step 2: Add health check test

Create `test/haul_web/controllers/health_controller_test.exs`:
- Test `GET /healthz` returns 200
- Test response body is "ok"
- Test content-type is text/plain

**Verify**: Test passes with `mix test test/haul_web/controllers/health_controller_test.exs`.

## Step 3: Add route

Modify `lib/haul_web/router.ex`:
- Add pipeline-less scope with `get "/healthz"` → `HaulWeb.HealthController, :index`
- Place before the browser scope

**Verify**: `mix compile` succeeds. Health check test still passes.

## Step 4: Update prod config — force_ssl exclusion

Modify `config/prod.exs`:
- Add `paths: ["/healthz"]` to the `force_ssl` exclude list

**Verify**: `mix compile` succeeds.

## Step 5: Enable SSL for Ecto

Modify `config/runtime.exs`:
- Uncomment `ssl: true` in the Repo config block

**Verify**: `mix compile` succeeds.

## Step 6: Create fly.toml

Create `fly.toml` at project root:
- `app = "haul-page"`
- `primary_region = "iad"`
- HTTP service on port 4000, force HTTPS
- Auto-stop/start machines, min 0
- Health check at `/healthz`
- `shared-cpu-1x`, 256MB RAM
- Deploy command not needed (Dockerfile CMD handles it)

**Verify**: File is valid TOML (flyctl validates on deploy).

## Step 7: Fix CI deploy job

Modify `.github/workflows/ci.yml`:
- Change deploy `needs` from `[test, quality, guardrails]` to `[test, quality]`

**Verify**: YAML is valid.

## Step 8: Run full test suite

Run `mix test` to ensure nothing is broken.

**Verify**: All tests pass.

## Testing strategy

- **Unit test**: `HealthControllerTest` — GET /healthz returns 200 "ok"
- **Compile check**: All config changes verified via `mix compile`
- **Full suite**: `mix test` for regression
- **Manual verification**: `fly.toml` validated by flyctl during deploy (not tested locally)

## Commit plan

Single commit: "Add fly.toml, health check endpoint, and Neon SSL config"

Includes:
- `fly.toml`
- `lib/haul_web/controllers/health_controller.ex`
- `test/haul_web/controllers/health_controller_test.exs`
- Modified: `router.ex`, `runtime.exs`, `prod.exs`, `ci.yml`
