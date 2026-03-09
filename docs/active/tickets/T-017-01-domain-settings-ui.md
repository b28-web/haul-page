---
id: T-017-01
story: S-017
title: domain-settings-ui
type: task
status: open
priority: medium
phase: done
depends_on: [T-013-01, T-012-01, T-016-01]
---

## Context

Let Pro+ operators configure a custom domain through the admin UI. Show CNAME instructions, verify DNS, and provision TLS.

## Acceptance Criteria

- `/app/settings/domain` LiveView
- Feature-gated: Starter operators see upgrade prompt
- Current state display: "Your site is at slug.haulpage.com" or "Custom domain: www.example.com (verified)"
- Add domain form: enter custom domain → show CNAME instructions ("Point www.example.com CNAME to haulpage.com")
- "Verify DNS" button → background job checks CNAME resolution
- On verification success: trigger TLS provisioning, show "Setting up SSL..."
- On verification failure: show helpful error ("DNS not yet propagated — try again in a few minutes")
- Remove domain: revert to subdomain, clean up cert
- Domain status: pending verification → provisioning TLS → active
