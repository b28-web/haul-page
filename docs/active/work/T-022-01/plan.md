# T-022-01 Plan: ProxyTenantResolver Plug

## Step 1: Create ProxyTenantResolver plug

Create `lib/haul_web/plugs/proxy_tenant_resolver.ex`:
- `init/1`: passthrough
- `call/2`: read `conn.path_params["slug"]`, query Company by slug, set assigns or 404

Verify: compile check (`mix compile`)

## Step 2: Create ProxyTenantHook

Create `lib/haul_web/live/proxy_tenant_hook.ex`:
- `on_mount(:resolve_tenant, ...)`: read session `tenant_slug` + `proxy_slug`, load Company, set socket assigns

Verify: compile check

## Step 3: Add proxy routes to router

Modify `lib/haul_web/router.ex`:
- Add `:proxy_browser` pipeline inside `dev_routes` guard
- Add `/proxy/:slug` scope with matching routes

Verify: `mix compile`, `mix phx.routes | grep proxy`

## Step 4: Write ProxyTenantResolver tests

Create `test/haul_web/plugs/proxy_tenant_resolver_test.exs`:
- Test valid slug resolution
- Test unknown slug → 404
- Test session values set correctly

Verify: `mix test test/haul_web/plugs/proxy_tenant_resolver_test.exs`

## Step 5: Write integration tests via router

Create `test/haul_web/plugs/proxy_routes_test.exs`:
- GET `/proxy/:slug/` → renders home page with correct tenant
- GET `/proxy/:slug/scan/qr` → generates QR
- GET `/proxy/nonexistent/` → 404
- LiveView `/proxy/:slug/book` mounts with correct tenant

Verify: `mix test test/haul_web/plugs/proxy_routes_test.exs`

## Step 6: Run full test suite

Run `mix test` to verify no regressions.

## Testing Strategy

- Unit tests for ProxyTenantResolver plug (isolated plug calls)
- Integration tests through router (HTTP requests to proxy routes)
- LiveView mount tests for ProxyTenantHook (via proxy live routes)
- Full suite regression check
