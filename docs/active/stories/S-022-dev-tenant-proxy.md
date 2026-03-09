---
id: S-022
title: dev-tenant-proxy
status: open
epics: [E-012, E-001]
---

## Dev Tenant Proxy

Add a `/proxy/:slug` route scope that mirrors all public tenant routes, resolving the tenant from the URL path instead of the hostname. Gated behind `dev_routes` — only available in dev/test.

## Scope

- `/proxy/:slug` scope mounting all public tenant routes: home, scan, book, pay, chat, QR
- `ProxyTenantResolver` plug that reads `:slug` from path params, looks up Company, sets tenant assigns (same shape as `TenantResolver`)
- LiveView `on_mount` hook for proxy routes that carries tenant from path params
- Internal links within proxied pages use `~p"/proxy/#{@slug}/scan"` style paths
- Guarded by `if Application.compile_env(:haul, :dev_routes)` — compiled out in prod
- Tests verifying all proxied routes resolve correct tenant and render content
