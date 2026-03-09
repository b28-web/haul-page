# T-009-02 Design — Address Autocomplete Hook

## Decision 1: JS-rendered dropdown vs LiveView-rendered

### Option A: JS hook renders dropdown (DOM manipulation)
- Hook fetches from `/api/places/autocomplete`, builds dropdown HTML, handles keyboard nav
- No round-trip to server for each keystroke display update
- Simpler LiveView — just receives the final selected address via `pushEvent`
- Matches how combobox widgets typically work (client-side UI)

### Option B: LiveView renders dropdown (server-side)
- Hook sends input to LiveView, LiveView fetches and assigns suggestions, re-renders
- More "LiveView-native" but adds latency (client → LV → proxy → LV → client)
- Complicates the hook/template interaction — need to manage open/close state across client/server

**Decision: Option A — JS-rendered dropdown.** The autocomplete is a fast, self-contained interaction that benefits from client-side rendering. The API call goes directly to our proxy endpoint. LiveView only needs to know the final selected value. This matches the StripePayment hook pattern — JS handles the widget, pushEvent sends results to LiveView.

## Decision 2: Structured address fields and geocoding

### Option A: Add lat/lng, street, city, state, zip to Job now
- Requires migration
- Ticket AC says "populates street, city, state, zip fields on the form" and "Geocode lat/lng stored on Job"
- But Google Places Autocomplete returns `description` (full address string) and `structured_formatting` (main_text/secondary_text), not discrete address components
- Getting true structured fields requires Place Details API call — not built in T-009-01

### Option B: Store full address in existing field, add lat/lng and place_id only
- `address` already stores the full string — set it to `description` from autocomplete
- Add `place_id` (for future geocoding) and `latitude`/`longitude` (nullable, for future use)
- Skip street/city/state/zip parsing — that's a separate concern
- The AC says "populates street, city, state, zip fields on the form" but the form only has one address field

### Option C: Defer all new fields, just set the address string
- Minimum viable: hook selects a suggestion, sets address field to the full description
- No schema changes, no migration
- Matches the form as it exists

**Decision: Option C — Just set the address string.** The ticket AC mentions populating "street, city, state, zip fields on the form" but these fields don't exist on the form or the Job resource. Adding them is scope creep beyond what T-009-01 built. The core value of this ticket is the autocomplete UX — type, see suggestions, select one. The address field gets the full address string. Geocoding and structured address parsing can be a follow-up ticket when dispatch routing is actually needed.

We'll store the `place_id` as a data attribute on the hook element for potential future use, but won't add new Job attributes or require a migration.

## Decision 3: Keyboard navigation pattern

Standard ARIA combobox pattern:
- Arrow Down/Up: navigate suggestions
- Enter: select highlighted suggestion
- Escape: close dropdown
- Tab: close dropdown and move focus normally
- Home/End: jump to first/last suggestion

The hook manages `aria-activedescendant` pointing to the highlighted option's ID.

## Decision 4: Debounce and fetch strategy

- 300ms debounce (per ticket AC)
- Minimum 3 characters before fetching (proxy enforces this anyway, but skip the call client-side)
- Abort in-flight requests when new input arrives (use AbortController)
- Show loading state while fetching (optional, keep simple)
- Cache nothing — queries are cheap and results change with input

## Decision 5: Form integration

When user selects a suggestion:
1. Set the input's value to `suggestion.description`
2. Dispatch an `input` event on the element to trigger `phx-change="validate"`
3. Optionally `pushEvent("address_selected", %{place_id, description})` for server tracking

When user types manually (no selection):
- Normal form behavior — the typed text goes through as the address
- This is the "graceful degradation" path

## Architecture Summary

```
User types → [300ms debounce] → fetch /api/places/autocomplete?input=...
                                         ↓
                              JSON response: {suggestions: [...]}
                                         ↓
                              Hook renders dropdown (Tailwind-styled)
                                         ↓
User selects → input.value = description → dispatch "input" event → LV validates
```

The hook is entirely self-contained. LiveView doesn't need new events or assigns for autocomplete — the existing `validate` event handles the address field value change naturally.
