---
id: T-012-03
story: S-012
title: wildcard-dns
type: task
status: done
priority: medium
phase: done
depends_on: [T-012-01]
---

## Context

Configure wildcard DNS on `*.haulpage.com` (or chosen platform domain) so any subdomain routes to the Fly app without per-operator DNS changes.

## Acceptance Criteria

- Wildcard DNS record: `*.haulpage.com` → Fly app IP (A/AAAA records)
- Fly.io wildcard TLS certificate configured
- Bare `haulpage.com` serves the marketing/signup page (not an operator site)
- `anything.haulpage.com` hits the app and is resolved by TenantResolver plug
- Document the DNS setup in the onboarding runbook
