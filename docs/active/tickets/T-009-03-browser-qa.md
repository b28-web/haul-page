---
id: T-009-03
story: S-009
title: browser-qa
type: task
status: done
priority: medium
phase: done
depends_on: [T-009-02]
---

## Context

Automated browser QA for the address autocomplete story. Verify the autocomplete hook works in the booking form — suggestions appear, selection populates fields, and graceful degradation works when the API is unavailable.

## Test Plan

1. `just dev` — ensure dev server is running
2. Navigate to `http://localhost:4000/book`
3. Type "123 Main" into the address field using `browser_type`
4. Wait briefly for debounce + API response
5. Snapshot and verify:
   - Suggestion dropdown is present with `role="listbox"`
   - At least one suggestion item visible
6. Click the first suggestion (or use keyboard: arrow down + enter)
7. Snapshot and verify:
   - Street, city, state, zip fields populated
   - Dropdown dismissed
8. Test graceful degradation:
   - If `GOOGLE_PLACES_API_KEY` is unset in dev, type an address manually
   - Form should still accept the input — no broken UI or JS errors
9. Check server logs — no 500 errors on `/api/places/autocomplete`

## Acceptance Criteria

- Autocomplete dropdown appears on input (when API key configured)
- Selecting a suggestion populates structured address fields
- Form works without autocomplete when API key is missing
- Accessible: listbox role, keyboard navigable
- No server errors
