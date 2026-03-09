---
id: T-023-03
story: S-023
title: impersonation
type: task
status: open
priority: high
phase: ready
depends_on: [T-023-02]
---

## Context

Superadmin needs to view the `/app` panel as any tenant operator — see their dashboard, content, settings — to debug issues and test the experience. This must be secure, auditable, and impossible to accidentally leave on.

## Acceptance Criteria

- "Impersonate" action (from account detail or accounts list):
  - Stores in session: `impersonating_slug`, `impersonating_since` (UTC timestamp), `real_user_id`
  - Redirects to `/app` with tenant context set to the impersonated company
  - Session auto-expires after 1 hour (checked on every request)
- Impersonation banner:
  - Rendered on every page during impersonation (injected via root layout or hook)
  - Shows: "Viewing as [Business Name] ([slug]) — [time remaining] — Exit"
  - "Exit" clears impersonation session keys and redirects to `/admin/accounts`
  - Banner is visually prominent (e.g., fixed top bar, warning color) — cannot be missed
- Tenant resolution during impersonation:
  - `TenantResolver` (or an additional plug) checks for `impersonating_slug` in session
  - If present and not expired: resolve tenant from that slug instead of hostname
  - If expired: clear session keys, redirect to `/admin` with flash "Impersonation session expired"
- Security constraints:
  - While impersonating, `/admin` routes return 404 — no privilege stacking
  - All Ash actions during impersonation are tagged with `actor: admin_user` in metadata (not the impersonated tenant user)
  - Audit log: `Logger.info` with structured metadata on impersonation start, end, and expiry: `%{event: "impersonation_start", admin_user_id: ..., target_slug: ..., timestamp: ...}`
  - Impersonation session is invalidated on admin logout
- Security tests:
  - Tenant users cannot set impersonation session keys (even by tampering — keys are ignored without valid admin session)
  - Expired impersonation redirects to `/admin`
  - `/admin` is inaccessible during impersonation
  - Audit log entries are emitted for start/end/expiry
