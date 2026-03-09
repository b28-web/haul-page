---
id: S-012
title: tenant-routing
status: open
epics: [E-010, E-008]
---

## Tenant Routing (Phase 2)

Resolve the active tenant from the incoming HTTP request so a single Fly app can serve multiple operators. This is the core infrastructure for shared multi-tenant hosting.

## Scope

- Plug middleware that resolves tenant from request:
  1. Custom domain lookup (Host header → Company by domain)
  2. Subdomain extraction (`slug.haulpage.com` → Company by slug)
  3. Fallback to demo/default tenant for bare domain
- Company resource gains `domain` and `subdomain` fields
- Tenant context set on conn/socket for all downstream Ash operations
- LiveView socket also resolves tenant on connect (mount + handle_params)
- Wildcard DNS on `*.haulpage.com` (Fly.io supports this)
- Custom domain TLS provisioning via `fly certs add` (background job)
- Cross-tenant request tests: operator A's domain must never serve operator B's data
