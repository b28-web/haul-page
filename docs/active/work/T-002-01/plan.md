# Plan — T-002-01 Landing Page Markup

## Step 1: Add operator config defaults

**Files:** `config/config.exs`
**What:** Add `config :haul, :operator, %{...}` with all default values (business_name, phone, email, tagline, service_area, coupon_text, services list).
**Verify:** `mix compile` succeeds.

## Step 2: Add runtime env var overrides

**Files:** `config/runtime.exs`
**What:** Read `OPERATOR_BUSINESS_NAME`, `OPERATOR_PHONE`, `OPERATOR_EMAIL`, `OPERATOR_TAGLINE`, `OPERATOR_SERVICE_AREA` from env, merge into operator config. Apply to all environments (not just prod).
**Verify:** Config reads correctly — `Application.get_env(:haul, :operator)` returns merged map.

## Step 3: Update PageController

**Files:** `lib/haul_web/controllers/page_controller.ex`
**What:** Read operator config, assign all fields to conn. Use `put_layout(conn, false)` to skip app layout. Pass `page_title` assign.
**Verify:** Controller compiles. Route still renders (even with old template).

## Step 4: Replace home template

**Files:** `lib/haul_web/controllers/page_html/home.html.heex`
**What:** Replace Phoenix boilerplate with full landing page markup:
- Hero section with eyebrow, h1, subtitle, tagline, phone link, contact row
- Services grid iterating `@services` assign
- Why Hire Us section with dash-prefixed list
- Footer CTA with phone button and print button
- Tear-off strip (hidden on screen, visible in print)
All content from assigns. Responsive Tailwind classes. Dark theme tokens.
**Verify:** `GET /` renders the landing page. Visual check at 320px, 768px, 1440px.

## Step 5: Add print styles

**Files:** `assets/css/app.css`
**What:** Add `@media print` block with:
- White background, black text, transparent sections
- `.no-print { display: none }` (alternative to Tailwind `print:hidden` for non-Tailwind elements)
- Tear-off strip styles: flex layout, vertical text, dashed borders
- `@page { margin: 0.3in; size: letter; }`
- Typography overrides for print (Oswald h1 42pt, h2 22pt, body 11pt)
**Verify:** Print preview shows correct layout with tear-off strip.

## Step 6: Write tests

**Files:** `test/haul_web/controllers/page_controller_test.exs`
**What:**
- Test `GET /` returns 200
- Test response contains business name from config
- Test response contains phone number as tel: link
- Test response contains email as mailto: link
- Test response contains all section headings (What We Do, Why Hire Us, Ready to Get Started?)
- Test response contains service titles from config
- Test page renders without app layout navbar
**Verify:** `mix test test/haul_web/controllers/page_controller_test.exs` passes.

## Step 7: Verify acceptance criteria

Manual check against all acceptance criteria:
- [x] Route `GET /` serves server-rendered page (PageController, not LiveView)
- [x] Four sections with correct typography
- [x] Dark theme colors
- [x] Phone as tel: link, email as mailto: link
- [x] Icons via Heroicons
- [x] Responsive 320px–1440px
- [x] Works with JS disabled
- [x] Operator config from runtime config
- [x] Print as Poster button with window.print()

## Testing strategy

- **Unit tests:** PageController test — response status, content assertions, link formats
- **No integration tests needed:** No LiveView, no JS, no DB queries
- **Visual verification:** Manual — responsive breakpoints, print preview
- **Config tests:** Verify operator config merging works correctly
