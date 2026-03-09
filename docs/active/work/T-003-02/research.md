# Research — T-003-02 Booking LiveView

## Ticket summary

Build `/book` as a LiveView form. Customers submit name, phone, email (opt), address, item description, preferred dates. Creates a Job in `:lead` state via `:create_from_online_booking`.

## Existing codebase

### Job resource (`lib/haul/operations/job.ex`)

- `Haul.Operations.Job` — Ash resource with AshStateMachine, AshPostgres
- Multi-tenancy: `:context` strategy (schema-per-tenant via `ProvisionTenant`)
- Action: `:create_from_online_booking` — accepts `[:customer_name, :customer_phone, :customer_email, :address, :item_description, :preferred_dates, :notes]`
- Required fields: `customer_name`, `customer_phone`, `address`, `item_description`
- Optional: `customer_email`, `notes`, `preferred_dates` (defaults to `[]`, type `{:array, :date}`)
- State machine starts at `:lead`

### Multi-tenancy model

- Companies are created in public schema (`companies` table)
- `ProvisionTenant` change creates `tenant_{slug}` schema + runs tenant migrations
- Every Ash operation on Job requires a `tenant:` option
- **No default tenant configured.** The operator config has no slug/company reference.
- The booking form is public (no auth). Must resolve which tenant to use.
- Single-operator deployment model: one app instance = one company. Need a way to resolve the operator's tenant at runtime.

### Router (`lib/haul_web/router.ex`)

- Browser pipeline: session, live_flash, root_layout, CSRF, secure headers
- Existing LiveViews: `ScanLive` at `/scan`
- `/book` route does not exist yet — needs `live "/book", BookingLive`

### LiveView pattern (`lib/haul_web/live/scan_live.ex`)

- `use HaulWeb, :live_view`
- `mount/3` loads operator config via `Application.get_env(:haul, :operator, [])`
- Inline `render/1` with `~H` sigil
- No form handling patterns exist yet — this will be the first LiveView with a form

### Core components (`lib/haul_web/components/core_components.ex`)

- `<.input>` — supports text, email, tel, date, textarea, select, checkbox
  - Uses daisyUI classes: `input`, `textarea`, `select`
  - Error display with `hero-exclamation-circle` icon
  - `field` attr accepts `Phoenix.HTML.FormField`
- `<.button>` — daisyUI `btn btn-primary` styling
- `<.flash>` — toast notifications (top-right)
- `<.icon>` — Heroicons via `hero-*` names

### Design system (from landing page + scan page)

- Dark theme default: bg `0 0% 6%`, fg `0 0% 92%`
- Containers: `px-4 py-12 md:py-16 max-w-4xl mx-auto`
- Headings: `text-3xl md:text-4xl font-bold`, Oswald font (`font-display`)
- Labels: `text-[10px] tracking-[0.3em] uppercase text-muted-foreground`
- CTA buttons: `bg-foreground text-background px-8 py-3 font-bold font-display uppercase tracking-wider`
- No border-radius (radius: 0 in theme)

### Test patterns

- `HaulWeb.ConnCase` for LiveView tests — `import Phoenix.LiveViewTest`
- `live(conn, "/path")` returns `{:ok, view, html}`
- Job tests require tenant provisioning: create Company → derive tenant → pass to Ash operations
- LiveView tests (scan_live_test.exs) don't touch the database — just assert rendering

### Operator config

- `config :haul, :operator` — business_name, phone, email, tagline, service_area, coupon_text, services
- No company slug or tenant reference in operator config
- `config/runtime.exs` merges env var overrides at boot

## Constraints & assumptions

1. **Tenant resolution for public form**: The app is single-operator. There must be exactly one Company in the DB, or the operator config needs a slug to derive the tenant. The seeds.exs doesn't create a Company yet.
2. **No AshPhoenix**: No `ash_phoenix` in deps. Form integration will use plain Phoenix forms with manual Ash changeset calls.
3. **preferred_dates is `{:array, :date}`**: Need a UX approach for selecting multiple dates. Could be 3 separate date inputs or a dynamic add/remove pattern.
4. **No photo upload**: Spec mentions "load photos" but acceptance criteria don't include it. Deferred.
5. **Success state**: Show confirmation message, not redirect. "We'll contact you" copy.
6. **Mobile-first**: Large inputs, proper input types (tel, email, date).

## Key files to modify/create

| File | Action |
|------|--------|
| `lib/haul_web/live/booking_live.ex` | Create — the LiveView module |
| `lib/haul_web/router.ex` | Modify — add `live "/book", BookingLive` |
| `test/haul_web/live/booking_live_test.exs` | Create — tests |
| `config/config.exs` | Possibly modify — add operator slug for tenant resolution |
| `priv/repo/seeds.exs` | Possibly modify — seed a default Company |

## Open questions

1. How to resolve the tenant for the public booking form? Options: (a) add a slug to operator config and look up the company, (b) seed a default company and store its tenant in app config, (c) hardcode a default tenant for single-operator mode.
2. Should AshPhoenix be added as a dependency for form helpers, or use plain Phoenix forms?
3. How many preferred date inputs to show? Fixed 3, or dynamic add/remove?
