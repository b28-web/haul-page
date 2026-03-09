# T-009-02 Research — Address Autocomplete Hook

## Scope

Wire the Places proxy (T-009-01) into the booking form's address field via a LiveView JS hook. Debounce, dropdown, keyboard nav, accessibility, geocode storage.

## Existing Code

### Places Proxy (T-009-01 — dependency, already built)

**`lib/haul_web/controllers/places_controller.ex`**
- Single `autocomplete/2` action, `GET /api/places/autocomplete?input=...`
- Returns `%{suggestions: [...]}` JSON
- Requires `input` >= 3 chars; returns empty list otherwise

**`lib/haul/places.ex`** — behaviour dispatch
- Configurable adapter: `Haul.Places.Sandbox` (dev/test) or `Haul.Places.Google` (prod)
- `autocomplete(input)` returns `{:ok, [suggestion]}` where suggestion is:
  ```
  %{place_id: string, description: string,
    structured_formatting: %{main_text: string, secondary_text: string}}
  ```

**`lib/haul/places/sandbox.ex`** — returns 3 static suggestions, sends `{:autocomplete_called, input}` for test assertions.

**`lib/haul/places/google.ex`** — calls Google Places (New) Autocomplete API, transforms response to match sandbox shape.

### Booking LiveView

**`lib/haul_web/live/booking_live.ex`**
- Form built with `AshPhoenix.Form.for_create(Job, :create_from_online_booking, ...)`
- Address field at line 189-196: `<.input field={@form[:address]} label="Pickup Address" ...>`
- Standard `<.input>` component from core_components.ex — renders `<input>` inside a `<div>` with label and error display
- Events: `validate` (form validation), `submit` (create job), `cancel-upload`, `reset`

### Job Resource

**`lib/haul/operations/job.ex`**
- `:address` — single string field, required
- **No structured address fields** (street, city, state, zip) or geocode fields (lat, lng)
- The ticket says "Geocode lat/lng stored on the Job" and "populates street, city, state, zip fields"
- These fields don't exist yet — need to decide: add them now or defer?

### JS Hook Infrastructure

**`assets/js/app.js`**
- Imports colocated hooks + manually imported hooks
- Pattern: `import StripePayment from "./hooks/stripe_payment"`
- Registered: `hooks: {...colocatedHooks, StripePayment}`

**`assets/js/hooks/stripe_payment.js`**
- Reference pattern: `mounted()`, `pushEvent()`, `destroyed()`, `this.el`
- Export as default

### Core Components

**`lib/haul_web/components/core_components.ex`**
- `<.input>` renders different markup by type
- Text inputs render `<input>` wrapped in a div with label/errors
- Passes `{@rest}` through to the input element — can add `phx-hook`, `id`, `data-*` attrs

### Router

**`lib/haul_web/router.ex`**
- `GET /api/places/autocomplete` — PlacesController, already wired

### Test Infrastructure

- `test/haul_web/controllers/places_controller_test.exs` — tests the proxy endpoint
- `test/haul/places/google_test.exs` — tests Google adapter
- Sandbox adapter enables test assertions via `{:autocomplete_called, input}` message

## Key Constraints

1. **No geocode endpoint yet** — Google Places Autocomplete returns `place_id`, not lat/lng. Getting coordinates requires a separate Place Details call. The proxy only has autocomplete. Need to either:
   - Add a `/api/places/details` endpoint for geocoding (requires extending the proxy)
   - Store just the `place_id` and defer geocoding
   - Parse structured_formatting for address parts without a separate call

2. **No structured address fields on Job** — The ticket says populate street/city/state/zip, but Job only has `:address`. Adding new attributes requires a migration.

3. **LiveView form integration** — The hook must coexist with `phx-change="validate"`. When the hook sets the address value, it needs to trigger LiveView's change tracking. Options:
   - `pushEvent` to set a hidden field or trigger server-side assignment
   - `this.el.dispatchEvent(new Event("input", {bubbles: true}))` to trigger phx-change

4. **Tailwind-only styling** — No CSS framework for dropdown; must build with utility classes matching dark theme (bg-background, text-foreground, etc.)

5. **Accessibility** — ARIA combobox pattern: `role="combobox"`, `aria-expanded`, `aria-activedescendant`, `role="listbox"` on dropdown, `role="option"` on items.

## Files That Will Be Touched

- `assets/js/hooks/address_autocomplete.js` — NEW: the hook
- `assets/js/app.js` — MODIFY: import and register hook
- `lib/haul_web/live/booking_live.ex` — MODIFY: add hook to address input, handle events
- `lib/haul/operations/job.ex` — POSSIBLY MODIFY: add geocode/structured fields
- `test/haul_web/live/booking_live_test.exs` or similar — NEW or MODIFY: test autocomplete flow

## Open Questions for Design Phase

1. Should we add lat/lng and structured address fields to Job now, or defer to a later ticket?
2. How to handle geocoding — extend the proxy with a details endpoint, or skip for now?
3. Should the dropdown be rendered by the JS hook (DOM manipulation) or by LiveView (server-rendered)?
