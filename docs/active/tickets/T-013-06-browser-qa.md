---
id: T-013-06
story: S-013
title: browser-qa
type: task
status: open
priority: medium
phase: done
depends_on: [T-013-02, T-013-03, T-013-04, T-013-05]
---

## Context

Playwright MCP verification of the content admin UI. Confirm that an authenticated operator can view and edit their site content through the `/app` admin interface.

## Test Plan

1. Navigate to `/app` — should redirect to login if not authenticated
2. Authenticate as an owner user
3. Verify dashboard loads with operator name and site URL
4. Navigate to `/app/content/site` — verify SiteConfig form loads with current values
5. Edit a field (e.g., tagline), save — verify success flash
6. Navigate to public landing page — verify updated tagline appears
7. Navigate to `/app/content/services` — verify services list loads
8. Navigate to `/app/content/gallery` — verify gallery grid loads
9. Navigate to `/app/content/endorsements` — verify endorsements list loads
10. Resize to mobile (375x812) — verify admin sidebar collapses to hamburger menu

## Acceptance Criteria

- Full admin CRUD flow verified end-to-end via Playwright MCP
- Content changes reflect on public pages immediately
- Mobile admin layout is functional
