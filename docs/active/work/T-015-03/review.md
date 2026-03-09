# T-015-03 Review: Marketing Landing Page

## Summary

Marketing landing page for the bare platform domain (haulpage.com). When a user visits the bare domain (no subdomain), they see a marketing page selling the platform to haulers. Subdomain requests continue to resolve to the operator's landing page.

## Files changed

### Modified
- **`lib/haul_web/plugs/tenant_resolver.ex`** — Added `is_platform_host` assign and `platform_host?/2` public function. The plug now distinguishes bare platform domain from operator subdomains.
- **`lib/haul_web/controllers/page_controller.ex`** — `home/2` dispatches to `marketing/2` or `operator_home/2` based on `is_platform_host` assign.
- **`test/haul_web/controllers/page_controller_test.exs`** — Updated all tests to use subdomain host so they resolve to operator page (not marketing).

### Created
- **`lib/haul_web/controllers/page_html/marketing.html.heex`** — Marketing page template with nav, hero, features, how-it-works, pricing, footer.
- **`test/haul_web/controllers/marketing_page_test.exs`** — 7 tests covering marketing page content, pricing, features, CTAs, and absence of operator content.
- **`docs/active/work/T-015-03/`** — RDSPI work artifacts (research, design, structure, plan, progress, review).

## Test coverage

- 7 new tests for marketing page (all pass)
- 8 existing page controller tests updated and passing
- 14 tenant resolver tests passing (no changes needed)
- Full suite: 346 tests, 3 failures (pre-existing in SignupLiveTest from T-015-01 WIP, not related)

### What's tested
- Marketing page renders on bare domain
- All content sections present (hero, features, pricing, how-it-works)
- CTA links point to `/app/signup`
- Pricing tiers correct (Free, $29, $79, $149)
- Operator-specific content absent on marketing page
- Page title set correctly

### Gaps
- No browser/Playwright QA (handled by T-015-04)
- No test for production `BASE_DOMAIN=haulpage.com` (runtime config, tested via tenant resolver tests)

## Acceptance criteria status

| Criterion | Status |
|-----------|--------|
| `/` on bare domain serves marketing page | Done |
| TenantResolver distinguishes subdomain vs bare domain | Done |
| Hero: "Your hauling business online in 2 minutes" + CTA | Done |
| Demo link to live operator site | Done (CTA placeholder) |
| Pricing: 4 tiers (Free, $29, $79, $149) | Done |
| Features: site, booking, notifications, flyers, QR codes | Done |
| Social proof: testimonials | Placeholder (section not added; no testimonial data yet) |
| Mobile-responsive | Done (Tailwind responsive grid) |
| Dark theme, Oswald/Source Sans 3 | Done |
| No auth required | Done |

## Open concerns

1. **Social proof section omitted** — Ticket says "when available." No testimonial data source exists yet. Can be added when operator testimonials are collected.
2. **Demo link** — Currently points to `/app/signup`. Should point to a live demo operator site once one exists (e.g., `demo.haulpage.com`).
3. **Dev experience** — In dev on `localhost:4000`, the marketing page now shows by default (since base_domain = "localhost"). To see operator page in dev, use `junk-and-handy.localhost:4000`. This is correct behavior but may surprise developers.
