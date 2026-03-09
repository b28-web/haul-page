---
id: E-012
title: dev-tenant-preview
status: active
---

## Dev Tenant Preview

Provide a reliable way to view per-tenant pages during local development. The production tenant routing (subdomains + custom domains) is hostname-based and works on Fly, but `*.localhost` subdomains don't resolve in browsers. Add a `/proxy/:slug/...` route scope that resolves tenant from the URL path, gated behind `dev_routes` so it's never exposed in production.

### Goals

- `localhost:4000/proxy/joes/` renders Joe's landing page, `/proxy/joes/scan` renders his scan page, etc.
- All tenant LiveViews (booking, chat, payment) work under the proxy prefix
- Internal links within proxied pages stay within the `/proxy/:slug/` namespace
- Zero impact on production routing — the scope doesn't exist when `dev_routes` is false
- Custom domain CNAME → Fly → TenantResolver flow remains unchanged in production

## Ongoing concerns

- URL generation in templates/LiveViews must be proxy-aware in dev without polluting prod code paths
- LiveView WebSocket connections under `/proxy/:slug` must carry the tenant context
- Session cookies are same-origin (all on localhost) so no cookie scoping issues
- The proxy scope must not break any existing tenant routes or tests
