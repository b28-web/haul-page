---
id: S-023
title: superadmin-panel
status: open
epics: [E-010, E-008]
---

## Superadmin Panel

Platform owner view for administering all tenant accounts and impersonating operators for debugging/testing.

## Scope

- `/admin` route scope with dedicated `require_admin` guard
- `AdminUser` resource in public schema — completely separate from tenant-scoped `User`. Bootstrapped via `ADMIN_EMAIL` env var at startup — generates a one-time cryptographic setup link logged to stdout. No mix tasks, no signup UI.
- Account list: all companies with status, plan, tenant schema, created/updated dates
- Impersonation: "assume identity" to browse `/app` as any tenant operator
  - Session-based: stores impersonated company slug + original user ID
  - Persistent banner on all pages: "Viewing as [Company] — Exit"
  - All actions during impersonation are audit-logged with the real superadmin user ID
  - Exiting impersonation restores original session cleanly
- Security:
  - Admin routes return 404 (not 403) for non-admin users (don't reveal the route exists)
  - AdminUser auth is completely separate from tenant User auth — different session keys, different tokens
  - Impersonation session is time-limited (auto-expires after 1 hour)
  - Impersonation cannot escalate: superadmin-as-operator cannot access `/admin` routes
  - Audit log captures: who impersonated whom, when, and what actions were taken
  - Security tests: unauthorized access attempts, session tampering, privilege escalation
