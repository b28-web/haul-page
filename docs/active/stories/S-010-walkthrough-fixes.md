---
id: S-010
title: walkthrough-fixes
status: open
epics: [E-003, E-007]
---

## Walkthrough Fixes

Bugs and regressions found during a visual walkthrough of the app (2026-03-08). These are issues that slipped through earlier ticket completion or fell between ticket boundaries.

## Issues found

1. **`/book` crashes with KeyError** — `@max_photos` not assigned in BookingLive mount, but referenced in template (line 206). The upload config exists (max_entries: 5) but the assign is missing. This likely happened when photo upload UI was added to the template before T-003-03 finished implementing the full upload flow.

2. **Gallery images 404 on `/scan`** — Before/after images (`/images/gallery/before-1.jpg`, `after-1.jpg`, etc.) return 404. The scan page and gallery data model are complete (S-005), but no placeholder images exist. T-006-03 (seed-task) will seed DB content but won't necessarily provide image files.

## Scope

- Fix the booking page crash so `/book` renders without errors
- Add placeholder gallery images so `/scan` renders complete
- Add a smoke-test that catches page-level crashes on all public routes (prevents recurrence)
