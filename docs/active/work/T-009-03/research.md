# T-009-03 Research — Browser QA for Address Autocomplete

## Scope

Automated browser QA for the address autocomplete feature (T-009-02). Verify the autocomplete hook works in the booking form via Playwright MCP — suggestions appear, selection populates fields, and graceful degradation works.

## What exists

### Address autocomplete implementation (T-009-02)

**JS hook:** `assets/js/hooks/address_autocomplete.js` (~247 lines)
- Attached to input via `phx-hook="AddressAutocomplete"` on `#address-autocomplete`
- Debounces input 300ms, requires ≥3 chars before API call
- Fetches `GET /api/places/autocomplete?input=...`
- Renders `<ul role="listbox">` dropdown with suggestions
- Keyboard nav: ArrowDown/Up (cycle), Enter (select), Escape (dismiss), Tab (dismiss), Home/End
- Mouse: click on suggestions
- ARIA: `role="combobox"`, `aria-autocomplete="list"`, `aria-expanded`, `aria-activedescendant`
- On selection: populates `description` into input, triggers `input` event for LiveView validation, hides dropdown

**API endpoint:** `GET /api/places/autocomplete` → `PlacesController.autocomplete/2`
- Validates input ≥3 chars, delegates to `Haul.Places.autocomplete/1`
- Returns JSON: `{suggestions: [{place_id, description, structured_formatting: {main_text, secondary_text}}]}`

**Adapter system:** `Haul.Places` dispatches to configured adapter
- `Haul.Places.Sandbox` — default in dev/test, returns 3 static Springfield IL addresses
- `Haul.Places.Google` — production, calls Google Places (New) API
- Config: `config :haul, :places_adapter, Haul.Places.Sandbox` in test.exs
- Runtime: `GOOGLE_PLACES_API_KEY` env var switches to Google adapter

### Booking form (BookingLive)

**LiveView:** `lib/haul_web/live/booking_live.ex`
- Address field at lines 190-222: raw HTML with `phx-hook="AddressAutocomplete"`, `autocomplete="off"`, `id="address-autocomplete"`
- Wrapped in `<div class="relative">` for dropdown positioning
- Form validates via AshPhoenix — address is a required string field on Job

### Dev environment

- Dev server: `just dev` on port 4000, currently running
- Sandbox adapter active by default (no Google API key needed)
- Sandbox returns: "123 Main St, Springfield, IL 62701", "456 Main Ave, Springfield, IL 62702", "789 Main Blvd, Springfield, IL 62703"
- Tenant needed: `tenant_junk-and-handy` schema must exist for form submission

### Existing test coverage

**Unit/integration tests:**
- `test/haul_web/controllers/places_controller_test.exs` — 8 tests (endpoint validation, response structure)
- `test/haul_web/live/booking_live_autocomplete_test.exs` — 9 tests (hook attributes, form submission with manual address)

**No browser-level test** — this ticket fills that gap.

### Prior browser QA patterns

From T-003-04 (booking form QA):
- Navigate → snapshot → verify fields → test validation → fill form → submit → verify confirmation → mobile → server health
- Results tracked in `progress.md` step by step
- No code changes expected (QA-only ticket)

### Playwright MCP

`.mcp.json` configures `@playwright/mcp@latest --headless`
Available tools: `browser_navigate`, `browser_snapshot`, `browser_type`, `browser_click`, `browser_press_key`, `browser_fill_form`, `browser_resize`, `browser_wait_for`, `browser_console_messages`, etc.

## Key questions for design

1. **Sandbox adapter in dev?** — Yes, dev defaults to Sandbox. The dropdown will show Springfield addresses. This is sufficient for QA.
2. **Debounce timing** — 300ms delay after typing. Need to wait ~500ms after typing before snapshot.
3. **Dropdown visibility** — rendered as absolute-positioned `<ul>` inside the relative container. Should be visible in snapshot.
4. **Graceful degradation** — When API returns empty/errors, dropdown simply doesn't appear. Form still accepts manual input. Already tested in integration tests but needs browser verification.
5. **Single address field** — Job has a single `address` string field. The ticket mentions "street, city, state, zip fields populated" but the actual implementation stores the full description in one field. QA should verify the single field is populated correctly.

## Constraints

- No code changes expected — this is QA-only
- Sandbox adapter provides deterministic responses (good for assertions)
- Need to account for debounce delay in test timing
- Tenant must exist for form submission test (may already be provisioned from T-003-04)
