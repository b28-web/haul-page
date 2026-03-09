---
id: S-017
title: custom-domains
status: open
epics: [E-010, E-002]
---

## Custom Domains (Phase 3)

Let Pro+ operators use their own domain (`www.joeshauling.com`) instead of a subdomain. Managed through the admin UI with automated TLS provisioning.

## Scope

- Domain settings page in `/app`: enter custom domain, show CNAME instructions
- DNS verification: background job checks CNAME points to `haulpage.com`
- TLS provisioning via Fly.io API (`fly certs add`) — automated after DNS verification
- Company resource stores `custom_domain` and `domain_verified_at`
- Tenant routing Plug resolves custom domains via DB lookup (cached)
- Domain removal: operator can revert to subdomain, cert is cleaned up
- Handles www vs apex (recommend CNAME on www, show appropriate instructions)
- Pro tier feature gate — Starter operators see the option but hit upgrade prompt
