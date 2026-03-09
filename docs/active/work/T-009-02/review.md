# T-009-02 Review — Address Autocomplete Hook

## Summary

Implemented an AddressAutocomplete JS hook that wires the Places proxy (T-009-01) into the booking form's address field. The hook handles debouncing, fetching suggestions from `/api/places/autocomplete`, rendering a Tailwind-styled dropdown, keyboard navigation, ARIA accessibility, and graceful degradation.

## Files Created

| File | Purpose |
|------|---------|
| `assets/js/hooks/address_autocomplete.js` | LiveView JS hook — the core deliverable (~170 LOC) |
| `test/haul_web/live/booking_live_autocomplete_test.exs` | LiveView integration tests (9 tests) |

## Files Modified

| File | Change |
|------|--------|
| `assets/js/app.js` | Import + register AddressAutocomplete hook |
| `lib/haul_web/live/booking_live.ex` | Replace `<.input>` for address with hook-enabled custom markup |

## Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| `AddressAutocomplete` JS hook in `assets/js/hooks/` | ✓ | |
| Debounces input (300ms) before calling proxy | ✓ | Also skips calls for <3 chars |
| Renders suggestion dropdown (Tailwind-styled, keyboard-navigable) | ✓ | ArrowDown/Up, Enter, Escape, Tab, Home, End |
| On selection: populates address field on the form | ✓ | Sets input value + dispatches input event for LV |
| Geocode lat/lng stored on Job | DEFERRED | Job has no lat/lng fields; requires Place Details API not built in T-009-01. Follow-up ticket. |
| Populates street, city, state, zip fields | DEFERRED | Job has single `address` string; no structured fields exist. Populated with full description instead. |
| Dropdown dismisses on blur, Escape, or selection | ✓ | Blur with 200ms delay for click tolerance |
| Accessible: aria-expanded, aria-activedescendant, role="listbox" | ✓ | Full ARIA combobox pattern including role="combobox", aria-autocomplete, aria-controls |
| Graceful degradation: normal text input if proxy errors | ✓ | Fetch errors silently hide dropdown; manual typing works fine |
| LiveView test: autocomplete-selected and manually-typed addresses | ✓ | 9 tests covering both paths |

## Test Coverage

- **9 new tests** in `booking_live_autocomplete_test.exs`
  - Hook attribute presence (phx-hook, id, autocomplete=off, relative wrapper)
  - Form submission with manual address (graceful degradation path)
  - Form validation with/without address value
  - Places API endpoint integration (suggestions returned, short input handled)
- **201 total tests, 0 failures** — no regressions
- **Not tested (JS-only behavior):** Debounce timing, dropdown rendering, keyboard navigation, ARIA state changes. These require browser testing — deferred to T-009-03 (browser QA).

## Open Concerns

1. **Geocoding deferred** — The ticket AC mentions storing lat/lng on the Job for dispatch routing. The Job resource has no lat/lng attributes, and the Places proxy has no details/geocode endpoint. This needs a follow-up ticket when dispatch routing is implemented.

2. **Structured address fields deferred** — Same situation: Job has a single `address` string. Street/city/state/zip parsing would require either Place Details API or client-side parsing of `structured_formatting`. Not done.

3. **No JS test infrastructure** — The project has no Jest/Vitest setup. All JS behavior verification relies on Playwright browser QA (T-009-03). The hook is ~170 LOC of pure DOM manipulation — reasonable to verify manually + via browser tests.

4. **Dropdown styling** — Uses `bg-base-200`, `border-base-300`, `bg-base-300` for hover. These map to the project's dark grayscale theme. Visual polish may need adjustment during browser QA.

5. **AbortController browser support** — Supported in all modern browsers. No polyfill needed for the target audience.

## No Migration Required

The implementation uses the existing `address` string field on Job. No schema changes.
