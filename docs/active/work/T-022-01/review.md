# T-022-01 Review: ProxyTenantResolver Plug

## Summary

Implemented path-based tenant resolution for developer previews. Developers can now visit `localhost:4000/proxy/:slug/...` to preview any tenant's site without subdomain DNS configuration.

## Test Results

`mix test` — **760 tests, 0 failures** (1 excluded). Up from 742 baseline.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul_web/plugs/proxy_tenant_resolver.ex` | Plug that resolves tenant from URL path `:slug` param |
| `lib/haul_web/live/proxy_tenant_hook.ex` | LiveView on_mount hook for proxy tenant resolution |
| `test/haul_web/plugs/proxy_tenant_resolver_test.exs` | Unit tests for ProxyTenantResolver (6 tests) |
| `test/haul_web/plugs/proxy_routes_test.exs` | Integration tests via router (4 tests) |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul_web/router.ex` | Added `:proxy_browser` pipeline + `/proxy/:slug` scope inside `dev_routes` guard |
| `config/test.exs` | Added `config :haul, dev_routes: true` to enable proxy routes in test |
| `test/haul_web/controllers/debug_controller_test.exs` | Updated test expectation — route now exists in test since `dev_routes: true` |

## Acceptance Criteria Verification

- [x] `HaulWeb.Plugs.ProxyTenantResolver` reads `:slug` from `conn.path_params`
- [x] Looks up Company by slug (same query pattern as TenantResolver)
- [x] Sets `current_tenant`, `tenant`, `proxy_slug`, `is_platform_host` on conn
- [x] Returns 404 if slug doesn't match any Company
- [x] Route scope `/proxy/:slug` with all public tenant routes (home, scan/qr, scan, book, pay, start)
- [x] `ProxyTenantHook` on_mount reads session, sets tenant on socket with `proxy_slug`
- [x] Proxy scope uses separate `:proxy_browser` pipeline (swaps TenantResolver for ProxyTenantResolver)
- [x] `EnsureChatSession` runs in proxy pipeline
- [x] Existing tenant routes unchanged — no regressions
- [x] Not compiled in prod — guarded by `dev_routes`

## Test Coverage

- **ProxyTenantResolver plug**: Valid slug resolution, multiple companies, unknown slug → 404, nil slug → 404, session storage
- **Integration routes**: GET `/proxy/:slug/` (home), GET `/proxy/:slug/scan/qr`, LiveView `/proxy/:slug/book`, LiveView `/proxy/:slug/scan`
- **Regression**: Full suite passes (760 tests, 0 failures)

## Open Concerns

- **Template links**: Links within proxy-rendered pages (e.g., `href="/book"`) will navigate to `/book` instead of `/proxy/:slug/book`. A `tenant_path` helper was mentioned in the ticket's implementation notes as a "consider" item. This is a known limitation for a follow-up ticket.
- **QR codes**: QR controller generates URLs using `HaulWeb.Endpoint.url()` which gives the real host — this is correct behavior (QR codes should point to real URLs, not proxy URLs).
- **Router also modified by another agent**: The router was concurrently modified to add an `:admin_browser` pipeline by another ticket (likely S-023). Both changes coexist without conflict.
