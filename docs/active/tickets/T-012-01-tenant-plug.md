---
id: T-012-01
story: S-012
title: tenant-plug
type: task
status: open
priority: critical
phase: done
depends_on: [T-004-01]
---

## Context

Build the Plug that resolves tenant context from the HTTP request. This is the foundation of multi-tenant routing — every downstream operation depends on knowing which operator the request is for.

## Acceptance Criteria

- `HaulWeb.Plugs.TenantResolver` plug:
  1. Check Host header for known custom domain → look up Company by `domain` field
  2. Extract subdomain from Host (`slug.haulpage.com`) → look up Company by `slug` field
  3. Fallback: bare domain or unknown host → demo tenant (or 404)
- Sets `conn.assigns.current_tenant` (Company struct)
- Sets Ash tenant context on conn for all downstream operations
- Company resource gains: `slug` (unique, required), `domain` (unique, nullable), `subdomain_url` (computed)
- Migration adds `slug` and `domain` columns with unique indexes
- Plug is inserted in the router pipeline before all route scopes
- Tests:
  - Request with `joes-hauling.haulpage.com` resolves to Joe's company
  - Request with `www.joeshauling.com` resolves to Joe's company (custom domain)
  - Request with unknown host returns demo or 404
  - Cross-tenant isolation: resolved tenant scopes all Ash queries
