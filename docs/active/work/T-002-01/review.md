# Review — T-002-01 Landing Page Markup

## Summary of changes

### Files modified

| File | Change |
|------|--------|
| `config/config.exs` | Added `:operator` config with business_name, phone, email, tagline, service_area, coupon_text, and services list |
| `config/runtime.exs` | Added env var overrides (OPERATOR_BUSINESS_NAME, OPERATOR_PHONE, etc.) that merge into operator config |
| `lib/haul_web/controllers/page_controller.ex` | Reads operator config, assigns all fields to conn, skips app layout with `put_layout(false)` |
| `lib/haul_web/controllers/page_html/home.html.heex` | Complete replacement — four-section landing page with Hero, Services Grid, Why Hire Us, Footer CTA |
| `assets/css/app.css` | Added `@media print` block (~35 lines) for poster printing |
| `test/haul_web/controllers/page_controller_test.exs` | Replaced single test with 7 tests covering content, links, sections, layout, and progressive enhancement |

### No files created or deleted

All changes are modifications to existing files.

## Acceptance criteria verification

| Criteria | Status | Notes |
|----------|--------|-------|
| `GET /` serves server-rendered page (PageController) | ✅ | Not LiveView |
| Four sections with correct typography | ✅ | Oswald headings, Source Sans 3 body |
| Dark theme colors | ✅ | Uses `bg-background`, `text-foreground`, `text-muted-foreground` tokens |
| Phone as `tel:` link | ✅ | Strips non-digits for tel: href |
| Email as `mailto:` link | ✅ | |
| Icons via Heroicons | ✅ | Closest matches for Lucide icons |
| Responsive 320px–1440px | ✅ | Mobile-first with md/lg/sm breakpoints |
| Works with JS disabled | ✅ | Print button hidden without JS, everything else static |
| Operator config from runtime config | ✅ | Application env with env var overrides |
| Print as Poster with `window.print()` | ✅ | Progressive enhancement — button hidden by default, shown via inline JS |

## Test coverage

**7 tests, all passing.**

- Response status and operator identity presence
- Phone number as `tel:` link with digits-only href
- Email as `mailto:` link
- All four section headings present
- All six services from config rendered
- App layout navbar absent (layout bypass verified)
- Print button progressive enhancement

**Not tested (visual/manual):**
- Responsive layout at specific breakpoints
- Print preview rendering
- Tear-off strip in print
- Dark/light theme switching

## Icon mapping decisions

| Prototype (Lucide) | Implementation (Heroicons) | Rationale |
|--------------------|-----------------------------|-----------|
| Truck | `hero-truck` | Direct match |
| Trash2 | `hero-trash` | Direct match |
| TreePine | `hero-sparkles` | No tree icon in Heroicons; sparkles conveys cleanup |
| Wrench | `hero-wrench` | Direct match |
| Hammer | `hero-wrench-screwdriver` | No hammer in Heroicons; wrench-screwdriver is closest |
| Package | `hero-cube` | Close match for boxes/moving |
| Mail | `hero-envelope` | Direct match |
| MapPin | `hero-map-pin` | Direct match |

## Open concerns

1. **Icon fidelity**: TreePine→`hero-sparkles` and Hammer→`hero-wrench-screwdriver` are approximations. If exact icons matter, custom SVGs can be added to `priv/static/images/` or inline in template.

2. **Why Hire Us items are hardcoded**: Unlike services (configurable via operator config), the "Why Hire Us" list is hardcoded in the template. The spec doesn't call for these to be configurable, but when Content domain lands, they could move to config.

3. **Service area in eyebrow**: The eyebrow reads "Serving {@service_area}" which defaults to "Your Area". Operators should set `OPERATOR_SERVICE_AREA` to their actual area.

4. **Print tear-off strip not tested in CI**: Print layout is CSS-only and can only be verified manually via print preview. The `@media print` styles and tear-off strip should be visually verified before shipping.

5. **No `<meta description>` tag**: The root layout doesn't set a meta description. When Content domain lands, SiteConfig.meta_description should populate this.

6. **Subtitle "& Handyman Services" is hardcoded**: Not part of operator config. If some operators are junk-removal-only, this would need to be configurable. Low priority — can be addressed when Content domain arrives.
