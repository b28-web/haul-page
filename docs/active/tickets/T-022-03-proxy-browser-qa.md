---
id: T-022-03
story: S-022
title: proxy-browser-qa
type: task
status: open
priority: medium
phase: implement
depends_on: [T-022-02]
---

## Context

Verify the dev proxy works end-to-end with Playwright: navigate to `/proxy/:slug/` and walk through all tenant pages, confirming tenant resolution, content rendering, link navigation, and LiveView functionality.

## Acceptance Criteria

- Playwright test: navigate to `/proxy/junk-and-handy/` (or test tenant slug)
  - Landing page renders with correct business name and services
  - Click "Book Now" → navigates to `/proxy/:slug/book` (stays in proxy)
  - Booking form renders, can fill fields
  - Navigate to `/proxy/:slug/scan` — gallery renders
  - Navigate to `/proxy/:slug/start` — chat interface loads (or redirects to fallback)
- Verify: links on all pages stay within `/proxy/:slug/` namespace
- Verify: LiveView WebSocket connects and events work under proxy prefix
- Verify: switching slug (`/proxy/other-tenant/`) resolves to different tenant content
