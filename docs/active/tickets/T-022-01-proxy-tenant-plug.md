---
id: T-022-01
story: S-022
title: proxy-tenant-plug
type: task
status: done
priority: high
phase: done
depends_on: [T-024-04]
---

## Context

Create a `ProxyTenantResolver` plug and a `/proxy/:slug` route scope that mounts all public tenant routes behind a path-based tenant resolver. This gives developers a working way to preview any tenant's site at `localhost:4000/proxy/:slug/...` without needing subdomain DNS.

## Acceptance Criteria

- New plug `HaulWeb.Plugs.ProxyTenantResolver`:
  - Reads `:slug` from `conn.path_params`
  - Looks up Company by slug (same query as `TenantResolver.resolve_by_subdomain/1`)
  - Sets `conn.assigns.current_tenant`, `conn.assigns.tenant`, `conn.assigns.proxy_slug` (same shape as TenantResolver)
  - Returns 404 if slug doesn't match any Company
- New route scope in router, guarded by `if Application.compile_env(:haul, :dev_routes)`:
  ```
  scope "/proxy/:slug", HaulWeb do
    pipe_through [:browser]  # uses ProxyTenantResolver instead of TenantResolver
    get "/", PageController, :home
    get "/scan/qr", QRController, :generate
    live_session :proxy_tenant, on_mount: [{HaulWeb.ProxyTenantHook, :resolve_tenant}] do
      live "/scan", ScanLive
      live "/book", BookingLive
      live "/pay/:job_id", PaymentLive
      live "/start", ChatLive
    end
  end
  ```
- `ProxyTenantHook` on_mount: reads slug from `socket.assigns` or URL params, sets tenant on socket (mirrors `TenantHook` but path-based)
- The proxy scope uses a separate pipeline (or inline plug) that swaps `TenantResolver` for `ProxyTenantResolver`
- Existing tenant routes unchanged — no regressions
- Not compiled in prod (`dev_routes` guard)

## Implementation notes

- The proxy pipeline should include all `:browser` plugs EXCEPT `TenantResolver`, replacing it with `ProxyTenantResolver`
- `conn.assigns.proxy_slug` is set so templates can generate proxy-aware links
- The `EnsureChatSession` plug should still run in the proxy pipeline
- Consider a helper like `tenant_path(conn, "/scan")` that returns `/proxy/:slug/scan` when proxy_slug is set, `/scan` otherwise
