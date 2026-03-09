---
id: T-023-02
story: S-023
title: accounts-list
type: task
status: open
priority: high
phase: ready
depends_on: [T-023-01]
---

## Context

The superadmin needs to see all tenant accounts at a glance — who's signed up, what plan they're on, when they were created, and whether their site is actually live.

## Acceptance Criteria

- `Admin.AccountsLive` at `/admin/accounts`:
  - Table of all Companies with columns: slug, business name, plan, domain (if set), created date, status indicators
  - Status indicators: tenant provisioned (schema exists), has content (site_config populated), domain verified
  - Sortable by created date, business name
  - Search/filter by slug or business name
  - Click row → detail view showing company info, user count, recent activity
- Detail view (`/admin/accounts/:slug`):
  - Company attributes (all fields)
  - Associated users (email, created date, last login)
  - Tenant schema status
  - "Impersonate" button (links to T-023-03)
- Security:
  - All queries run without tenant scoping (superadmin reads from public schema)
  - No mutation actions exposed — this is read-only (edits happen via impersonation or console)
  - Tests: verify non-superadmin cannot access these routes
