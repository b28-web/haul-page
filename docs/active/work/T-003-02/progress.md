# Progress — T-003-02 Booking LiveView

## Completed steps

### Step 1: Add operator slug to config ✓
- Added `slug: "junk-and-handy"` to `:operator` config in `config/config.exs`

### Step 2: Update seeds ✓
- Replaced placeholder comment in `priv/repo/seeds.exs` with Company creation logic
- Seeds create a Company using operator config name/slug if none exists
- Company creation triggers `ProvisionTenant` which provisions the tenant schema

### Step 3: Add /book route ✓
- Added `live "/book", BookingLive` to browser scope in router

### Step 4: Create BookingLive module ✓
- Created `lib/haul_web/live/booking_live.ex`
- Uses `AshPhoenix.Form.for_create/3` for form integration
- `mount/3`: loads operator config, derives tenant, builds form
- `handle_event("validate")`: real-time validation via AshPhoenix.Form.validate
- `handle_event("submit")`: submits form, merges preferred dates, shows confirmation
- `handle_event("reset")`: rebuilds fresh form
- Two render states: form (default) and confirmation (after successful submit)
- Styled consistently with landing/scan pages (dark theme, Oswald headings, same CTA patterns)
- Three fixed date inputs for preferred dates, filtered on submit
- Mobile-optimized: input-lg sizing, proper input types (tel, email, date)

### Step 5: Write tests ✓
- Created `test/haul_web/live/booking_live_test.exs` with 13 tests
- Rendering tests: form elements, field labels, input types, operator phone
- Submission tests: success confirmation, operator phone display, form reset
- Validation tests: empty form errors, change validation

### Step 6: Compile and test ✓
- `mix compile --warnings-as-errors` passes clean
- 13/13 booking tests pass
- 86/86 full suite passes (0 failures)

## Deviations from plan

- Used `to_form/2` (kernel) instead of `AshPhoenix.Form.to_form/2` (doesn't exist as public API)
- Kept `ash_form` as a separate assign alongside `form` (the Phoenix.HTML.Form version) for cleaner AshPhoenix.Form operations
