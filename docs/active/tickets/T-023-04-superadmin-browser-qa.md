---
id: T-023-04
story: S-023
title: superadmin-browser-qa
type: task
status: open
priority: medium
phase: ready
depends_on: [T-023-03]
---

## Context

End-to-end Playwright QA for the superadmin panel: login as superadmin, browse accounts, impersonate an operator, verify the experience, exit impersonation.

## Acceptance Criteria

- Playwright test: superadmin login → `/admin` dashboard renders
- Navigate to `/admin/accounts` — accounts table shows test companies
- Click into account detail — company info and users displayed
- Click "Impersonate" — redirected to `/app`, impersonation banner visible
- Verify: tenant content matches the impersonated company (not the superadmin's)
- Verify: `/admin` returns 404 while impersonating
- Click "Exit" on banner — returned to `/admin/accounts`, banner gone
- Security smoke tests:
  - Login as regular user → `/admin` returns 404 page (not error, not redirect)
  - Direct navigation to `/admin/accounts/:slug` as regular user → 404
