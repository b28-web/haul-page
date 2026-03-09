# T-012-03 Plan: Wildcard DNS

## Step 1: Update fly.toml env vars

**Changes:**
- Set `PHX_HOST = "haulpage.com"`
- Add `BASE_DOMAIN = "haulpage.com"`

**Verification:** File diff review — no test needed for TOML changes.

## Step 2: Add check_origin config to runtime.exs

**Changes:**
- After the `BASE_DOMAIN` config block (line ~27), add check_origin configuration
- When `base_domain` is set, configure the endpoint with wildcard origin patterns

**Code:**
```elixir
if base_domain = System.get_env("BASE_DOMAIN") do
  config :haul, :base_domain, base_domain

  config :haul, HaulWeb.Endpoint,
    check_origin: ["//*.#{base_domain}", "//#{base_domain}"]
end
```

This replaces the existing 3-line BASE_DOMAIN block with a version that also sets check_origin.

**Verification:** `mix test` — existing tests should pass. The test env uses `config/test.exs` which doesn't set check_origin (not needed for test — no real WebSocket origins).

## Step 3: Add wildcard DNS documentation to onboarding runbook

**Changes to `docs/knowledge/operator-onboarding.md`:**
- Add section "## SaaS Platform DNS (One-Time Setup)" before the Troubleshooting section
- Content:
  1. Get Fly app IPs
  2. Configure DNS A/AAAA records (bare + wildcard)
  3. Add Fly wildcard certificate
  4. Add bare domain certificate
  5. Set BASE_DOMAIN secret
  6. Verify with curl and browser

**Verification:** Read the docs, ensure commands are correct.

## Step 4: Add test for check_origin wildcard pattern

**Changes to test:**
- Add an integration-style test that verifies the endpoint check_origin config can be set with wildcard patterns
- Actually: check_origin is Phoenix internals, not our code. Better to add a test that verifies TenantResolver works correctly when a wildcard subdomain pattern is used.
- The existing tests already cover this. Skip adding redundant tests.

**Verification:** `mix test test/haul_web/plugs/tenant_resolver_test.exs` passes.

## Step 5: Run full test suite

**Command:** `mix test`
**Expected:** All 201+ tests pass, 0 failures.

## Testing Strategy

- **Unit tests:** TenantResolver already tested for subdomain extraction, resolution, fallback
- **Integration tests:** Existing tests in tenant_resolver_test.exs cover the full plug pipeline
- **Manual verification (post-deploy):**
  - `curl https://haulpage.com/healthz` → `ok`
  - `curl https://anything.haulpage.com/healthz` → `ok`
  - Browser: `https://test-slug.haulpage.com` → resolves to tenant or fallback
  - LiveView WebSocket connects without CORS errors

## Commit Plan

Single commit: all changes are small and logically one unit (wildcard DNS configuration).
