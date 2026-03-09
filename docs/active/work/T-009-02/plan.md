# T-009-02 Plan — Address Autocomplete Hook

## Step 1: Create the AddressAutocomplete JS hook

**File:** `assets/js/hooks/address_autocomplete.js`

Implement the full hook with:
- `mounted()`: set ARIA attrs, create event listeners, init state
- Input handler with 300ms debounce, 3-char minimum
- Fetch from `/api/places/autocomplete?input=...` with AbortController for cancellation
- `renderDropdown()`: create `<ul role="listbox">` with `<li role="option">` items
- Tailwind classes matching dark theme: `bg-surface`, `border-border`, etc.
- `highlightIndex()`: manage visual highlight + `aria-activedescendant`
- Keyboard: ArrowDown/Up (navigate), Enter (select), Escape (close), Tab (close)
- `selectSuggestion()`: set input value, dispatch `input` event for LV, hide dropdown
- `hideDropdown()`: remove dropdown, reset ARIA
- Blur handler with 200ms delay (allows click on dropdown item before hiding)
- `destroyed()`: cleanup listeners, abort controller, remove dropdown

**Verify:** Load dev server, check JS compiles without errors.

## Step 2: Register hook in app.js

**File:** `assets/js/app.js`

- Import: `import AddressAutocomplete from "./hooks/address_autocomplete"`
- Add to hooks object: `{...colocatedHooks, StripePayment, AddressAutocomplete}`

**Verify:** Dev server loads without JS errors.

## Step 3: Update BookingLive template

**File:** `lib/haul_web/live/booking_live.ex`

Replace the address `<.input>` block with a custom version:
- Wrap in `<div class="relative">` for dropdown positioning context
- Keep the label and error display from `<.input>` component
- Use a raw `<input>` with `phx-hook="AddressAutocomplete"` and `id="address-autocomplete"`
- Set `autocomplete="off"` to prevent browser autocomplete from conflicting
- Keep `name={@form[:address].name}`, `value={@form[:address].value}` for form binding
- Keep `phx-debounce` removed (hook handles its own debounce)

**Verify:** Booking form loads, address field renders with hook attached.

## Step 4: Write tests

**File:** `test/haul_web/live/booking_live_autocomplete_test.exs`

Tests:
1. Address input renders with `phx-hook="AddressAutocomplete"` attribute
2. Form submission works with manually typed address (graceful degradation)
3. Form validates with address value present
4. Verify the places API endpoint returns suggestions (integration sanity — already tested in places_controller_test, but confirm end-to-end)

Note: Full autocomplete dropdown behavior (debounce, dropdown rendering, keyboard nav) is JS-only and would require browser testing (Playwright). The LiveView tests verify server-side integration.

**Verify:** `mix test test/haul_web/live/booking_live_autocomplete_test.exs` passes.

## Step 5: Run full test suite

**Verify:** `mix test` — all existing tests still pass, no regressions.

## Testing Strategy

- **Unit (JS):** Not adding Jest/Vitest — project doesn't have JS test infrastructure. The hook is tested via browser QA (T-009-03).
- **LiveView integration:** Verify hook attribute presence, form submission with/without autocomplete.
- **Browser QA:** Deferred to T-009-03 (the next ticket in the chain).
- **Manual verification:** Dev server, type in address field, see sandbox suggestions appear.
