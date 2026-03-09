# T-009-02 Structure — Address Autocomplete Hook

## Files Created

### `assets/js/hooks/address_autocomplete.js` — NEW
The main JS hook. Exports `AddressAutocomplete` object with LiveView hook lifecycle.

**Public interface (LiveView hook API):**
- `mounted()` — initialize debounce timer, attach event listeners, create dropdown container
- `destroyed()` — clean up listeners, remove dropdown, abort pending requests

**Internal methods:**
- `onInput(event)` — debounce handler, triggers fetch after 300ms
- `fetchSuggestions(query)` — GET to `/api/places/autocomplete?input=...` with AbortController
- `renderDropdown(suggestions)` — build/update dropdown DOM with Tailwind classes
- `hideDropdown()` — remove dropdown, reset ARIA state
- `onKeyDown(event)` — keyboard navigation (ArrowDown, ArrowUp, Enter, Escape, Tab)
- `selectSuggestion(suggestion)` — set input value, dispatch input event, hide dropdown
- `highlightIndex(index)` — update visual highlight and `aria-activedescendant`

**DOM structure created by hook:**
```html
<ul id="{el.id}-listbox" role="listbox" class="absolute z-50 ...">
  <li id="{el.id}-option-0" role="option" aria-selected="true|false">
    <span class="font-semibold">{main_text}</span>
    <span class="text-muted-foreground text-sm">{secondary_text}</span>
  </li>
  ...
</ul>
```

**ARIA attributes managed on the input element:**
- `role="combobox"` (set in mounted)
- `aria-expanded="true|false"`
- `aria-activedescendant="{option-id}"` (when navigating)
- `aria-controls="{listbox-id}"`
- `aria-autocomplete="list"`

### `test/haul_web/live/booking_live_autocomplete_test.exs` — NEW
LiveView integration test verifying:
- Form accepts manually typed addresses (no autocomplete selection)
- Form accepts addresses set via the autocomplete flow (pushEvent simulation)
- Address field renders with the hook attributes

## Files Modified

### `assets/js/app.js` — MODIFY
- Add: `import AddressAutocomplete from "./hooks/address_autocomplete"`
- Change hooks registration: `hooks: {...colocatedHooks, StripePayment, AddressAutocomplete}`

### `lib/haul_web/live/booking_live.ex` — MODIFY
- Replace the plain `<.input field={@form[:address]} ...>` with a version that:
  - Adds `phx-hook="AddressAutocomplete"`
  - Adds `id="address-autocomplete"` (hooks require a stable ID)
  - Wraps in a `<div class="relative">` for dropdown positioning
  - Disables browser autocomplete: `autocomplete="off"`

**No new LiveView events needed.** The existing `validate` event handles value changes. The hook is purely client-side.

## Files NOT Modified

- `lib/haul/operations/job.ex` — no new fields; address stays as single string
- `lib/haul_web/controllers/places_controller.ex` — no changes; proxy works as-is
- `lib/haul/places.ex` — no changes
- No migration needed

## Component Boundaries

```
BookingLive (Elixir)
  └── render/1
       └── <div class="relative">
            └── <input phx-hook="AddressAutocomplete" id="address-autocomplete" ...>
            └── [dropdown injected by JS hook]

AddressAutocomplete (JS)
  ├── input event listener → debounce → fetch
  ├── keydown event listener → keyboard nav
  ├── blur event listener → hide dropdown (with delay for click)
  └── DOM: creates/removes <ul> dropdown as sibling of input's wrapper
```

## Ordering

1. Create `address_autocomplete.js` hook
2. Register hook in `app.js`
3. Update BookingLive template to attach hook
4. Write tests
