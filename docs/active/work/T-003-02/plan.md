# Plan — T-003-02 Booking LiveView

## Step 1: Add operator slug to config

**File:** `config/config.exs`
**Change:** Add `slug: "junk-and-handy"` to `:operator` config keyword list.
**Verify:** `Application.get_env(:haul, :operator)[:slug]` returns `"junk-and-handy"`.

## Step 2: Update seeds to create default Company

**File:** `priv/repo/seeds.exs`
**Change:** After the existing summary output, add Company creation logic:
- Read operator config for business_name
- Check if Company exists, create if not
- Use `:create_company` action (auto-generates slug, provisions tenant)
**Verify:** `mix run priv/repo/seeds.exs` creates a Company and tenant schema.

## Step 3: Add /book route

**File:** `lib/haul_web/router.ex`
**Change:** Add `live "/book", BookingLive` inside the browser scope.
**Verify:** `mix phx.routes | grep book` shows the route.

## Step 4: Create BookingLive module

**File:** `lib/haul_web/live/booking_live.ex` (new)
**Implementation:**

### mount/3
- Load operator config (slug, phone, business_name)
- Derive tenant: `ProvisionTenant.tenant_schema(slug)`
- Build form: `AshPhoenix.Form.for_create(Job, :create_from_online_booking, tenant: tenant)`
- Assign: `:form` (to_form), `:submitted` (false), `:phone`, `:business_name`, `:page_title`

### handle_event("validate")
- `AshPhoenix.Form.validate(form, params)`
- Reassign form via `to_form`

### handle_event("submit")
- `AshPhoenix.Form.submit(form, params: params)`
- Success: assign `submitted: true`
- Error: reassign form with errors

### handle_event("reset")
- Rebuild fresh form, assign `submitted: false`

### render/1 — two states
**Form state (submitted == false):**
- Dark theme container matching site design
- Heading: "Book a Pickup" (Oswald, uppercase)
- Subheading with operator service area
- Form fields: name (text), phone (tel), email (email), address (text), item_description (textarea), 3× preferred date inputs
- Submit button styled like landing page CTA

**Confirmation state (submitted == true):**
- Check icon + "Thank You!" heading
- "We'll contact you shortly" copy
- Phone CTA link
- "Submit Another Request" button

### Preferred dates handling
- Three separate date inputs with names `form[preferred_date_1]`, `form[preferred_date_2]`, `form[preferred_date_3]`
- In validate/submit handlers, collect non-empty dates into list, merge into params as `preferred_dates`
- Or: use AshPhoenix form's params directly if array params work

## Step 5: Write tests

**File:** `test/haul_web/live/booking_live_test.exs` (new)

### Setup
- Create Company via Ash (provisions tenant schema)
- Ensure operator config slug matches Company slug
- on_exit: drop tenant schemas

### Test cases
1. **Renders form** — `live(conn, "/book")` returns HTML with "Book a Pickup"
2. **Shows required fields** — asserts name, phone, address, description labels present
3. **Shows email field** — asserts email input present
4. **Shows date inputs** — asserts date input fields present
5. **Validation shows errors** — submit empty form via `phx-change`, assert error messages
6. **Successful submission** — fill all required fields, submit, assert "Thank You" confirmation
7. **Confirmation shows phone** — after submit, operator phone displayed
8. **Reset returns to form** — click "Submit Another", assert form reappears
9. **Mobile input types** — assert `type="tel"` on phone, `type="email"` on email

## Step 6: Compile and test

- `mix compile --warnings-as-errors`
- `mix test test/haul_web/live/booking_live_test.exs`
- `mix test` (full suite to catch regressions)

## Testing strategy

| Layer | What | How |
|-------|------|-----|
| LiveView | Form renders, validates, submits | Phoenix.LiveViewTest |
| Integration | Job created in DB after submit | Assert Ash.read returns created job |
| Rendering | Correct HTML structure, classes | Assert HTML contains expected elements |
| Error paths | Missing required fields show errors | Submit with missing fields, assert errors |
