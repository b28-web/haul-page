---
id: T-013-01
story: S-013
title: app-layout
type: task
status: done
priority: high
phase: done
depends_on: [T-004-01]
---

## Context

Create the authenticated `/app` layout shell — sidebar nav, header with operator name, mobile-responsive. This is the container for all admin UI features.

## Acceptance Criteria

- `/app` route scope in router, requires authenticated owner/dispatcher
- `AppLive` layout with:
  - Sidebar: Dashboard, Content, Bookings, Settings nav links
  - Header: operator business name, user email, logout
  - Mobile: hamburger menu, slide-out sidebar
- Redirects to `/app/login` if not authenticated
- Uses existing AshAuthentication session (magic link or password)
- Dark theme consistent with public pages (Oswald headings, Source Sans 3 body)
- Empty dashboard page as initial landing: "Welcome, [name]. Your site is live at [url]."
