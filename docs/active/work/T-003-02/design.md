# Design — T-003-02 Booking LiveView

## Decision 1: Form integration approach

### Option A: Plain Phoenix forms + manual Ash changesets
- Build a `to_form/1` changeset manually, handle validation in `handle_event`
- Full control, no extra abstraction
- Must manually map Ash errors to form errors

### Option B: AshPhoenix.Form
- `ash_phoenix 2.3.20` is already in deps
- `AshPhoenix.Form.for_create/3` generates a form struct compatible with Phoenix forms
- Handles validation, error translation, and submission in one API
- Well-tested integration between Ash resources and LiveView forms

**Decision: Option B — AshPhoenix.Form.** It's already a dependency, purpose-built for this exact use case, and eliminates manual error mapping. The form will use `AshPhoenix.Form.for_create(Job, :create_from_online_booking)` with `tenant:` option.

## Decision 2: Tenant resolution for public booking form

### Option A: Add slug to operator config, look up Company at mount
- Add `slug: "junk-and-handy"` to `:operator` config
- In mount, query `Company` by slug, derive tenant
- Requires DB query on every page load

### Option B: Add `default_tenant` to app config
- `config :haul, :default_tenant, "tenant_junk-and-handy"`
- Set at deploy time, no DB lookup needed
- Simple, explicit

### Option C: Seed a default Company and resolve in Application.start
- Over-engineered for single-operator model

**Decision: Option A — operator config slug.** It's the most natural place (operator config already has all identity info), keeps tenant derivation consistent with `ProvisionTenant.tenant_schema/1`, and the DB lookup (one query for Company by slug) is negligible. We need to ensure seeds.exs creates the default Company.

However, looking more carefully: the booking form doesn't need to look up the Company — it just needs the tenant string. `ProvisionTenant.tenant_schema(slug)` is a pure function: `"tenant_#{slug}"`. So we add `slug` to operator config and derive the tenant string directly — no DB query.

**Revised: Add `slug` to operator config. Derive tenant as `"tenant_#{slug}"` in mount. No DB query.**

## Decision 3: Preferred dates UX

### Option A: Three fixed date inputs
- Always show 3 date fields (Preferred Date 1, 2, 3)
- Simple, predictable, mobile-friendly
- Empty dates filtered out before submission

### Option B: Dynamic add/remove
- Start with 1 date input, "Add another" button
- More complex JS/LiveView interaction
- Better UX for users who only want 1 date

### Option C: Single textarea ("List your preferred dates")
- Free-text, no structured data
- Doesn't match the `{:array, :date}` type

**Decision: Option A — three fixed date inputs.** Simplest implementation, good mobile UX (native date pickers), maps cleanly to the `{:array, :date}` attribute. Most customers will have 1-3 preferred dates. Empty ones are filtered.

## Decision 4: Success state

### Option A: Flash message + form reset
- Show flash notification, clear the form for another submission
- Simple but jarring — form disappears and reappears blank

### Option B: Replace form with confirmation panel
- After successful submit, replace the form with a "Thank you" confirmation
- Shows "We'll contact you shortly" message with operator phone as fallback
- Back-to-form via "Submit another" or navigate home
- Better UX — clear completion signal

**Decision: Option B — confirmation panel.** Assign `:submitted` boolean in socket. When true, render confirmation instead of form. Include operator phone number for immediate contact option.

## Decision 5: Layout and styling

Match existing dark theme patterns from landing page and scan page:
- Container: `max-w-2xl mx-auto` (narrower than landing page's `max-w-4xl` since it's a form)
- Section padding: `px-4 py-12 md:py-16`
- Heading: Oswald, uppercase, large
- Form inputs: Use `<.input>` core component (daisyUI styled)
- Submit button: `bg-foreground text-background` pattern (not daisyUI `btn-primary`)
- Input sizing: Add `input-lg` class override for mobile-friendly touch targets

## Decision 6: Validation approach

- `phx-change` on the form for real-time validation
- `phx-submit` for final submission
- AshPhoenix.Form handles validation via Ash changeset (required fields, types)
- Show errors only after field has been touched (AshPhoenix `used_input?` handles this)
- No custom client-side validation beyond HTML5 `type` and `required` attrs

## Architecture summary

```
mount/3
  → Load operator config (slug, phone, business_name)
  → Derive tenant from slug
  → Create AshPhoenix.Form for :create_from_online_booking
  → assign form, submitted: false

handle_event("validate", params, socket)
  → AshPhoenix.Form.validate(form, params)
  → Reassign form

handle_event("submit", params, socket)
  → AshPhoenix.Form.submit(form, params: params)
  → On success: assign submitted: true
  → On error: reassign form with errors

render/1
  → If submitted: confirmation panel
  → Else: form with inputs + real-time validation
```
