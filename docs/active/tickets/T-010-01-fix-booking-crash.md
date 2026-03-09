---
id: T-010-01
story: S-010
title: fix-booking-crash
type: bug
status: open
priority: high
phase: done
depends_on: []
---

## Context

`/book` crashes on load with `KeyError: key :max_photos not found`. The template at `booking_live.ex:206` references `{@max_photos}` in the photo upload label, but the assign is never set in `mount/3`.

The upload config already exists (`allow_upload :photos, max_entries: 5, ...`) so the value is known — it just needs to be assigned.

## Root cause

The photo upload UI was added to the template (likely during T-003-02 or early T-003-03 work) but the corresponding `assign(:max_photos, ...)` was not added to mount. The browser QA for booking (T-003-04) hasn't run yet, so this was never caught.

## Fix

1. In `lib/haul_web/live/booking_live.ex`, add `max_photos` to the socket assigns in `mount/3` — value should match the upload config's `max_entries` (currently 5)
2. Verify `/book` loads without error
3. Run `mix test` — no regressions

## Acceptance Criteria

- `/book` renders the booking form without errors
- The photo upload label displays the correct max count
- `mix test` passes
