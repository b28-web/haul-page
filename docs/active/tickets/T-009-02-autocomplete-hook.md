---
id: T-009-02
story: S-009
title: autocomplete-hook
type: task
status: done
priority: medium
phase: done
depends_on: [T-009-01, T-003-02]
---

## Context

Wire the Places proxy into the booking form's address field. A LiveView JS hook handles debouncing, fetching suggestions, rendering a dropdown, and populating structured address fields on selection.

## Acceptance Criteria

- `AddressAutocomplete` JS hook in `assets/js/hooks/`
- Debounces input (300ms) before calling `/api/places/autocomplete`
- Renders suggestion dropdown below the address input (Tailwind-styled, keyboard-navigable)
- On selection: populates street, city, state, zip fields on the form (via `pushEvent` to LiveView)
- Geocode lat/lng from the selected place stored on the Job (for future dispatch routing)
- Dropdown dismisses on blur, Escape, or selection
- Accessible: `aria-expanded`, `aria-activedescendant`, `role="listbox"` on dropdown
- Graceful degradation: if proxy returns empty or errors, address field remains a normal text input — no broken UI
- LiveView test: verify form accepts both autocomplete-selected and manually-typed addresses
