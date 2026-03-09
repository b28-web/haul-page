# T-002-04 Review — Browser QA

## Summary

Automated browser QA for the landing page completed using Playwright MCP. All acceptance criteria verified. No code changes were made.

## What Was Verified

### Desktop (default viewport ~1280px)
- **Hero section:** Business name eyebrow, H1 "Junk Hauling", subtitle, tagline, phone `tel:` link, email `mailto:` link, service area — all present and correct
- **Services grid:** H2 "What We Do" + 6 services (Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help) each with title and description
- **Why Hire Us:** H2 + 6 dash-prefixed benefit items
- **Footer CTA:** H2 "Ready to Get Started?", phone CTA button, Print as Poster button (JS-enabled), business info

### Mobile (375×812)
- All four sections present in correct order
- No horizontal overflow (`scrollWidth === innerWidth === 375`)
- Content identical to desktop (responsive layout working)

### Server Health
- All HTTP requests returned 200
- No 500 errors, crashes, or exceptions in server logs
- Tailwind/esbuild watchers running normally

## Files Changed

None. This was a verification-only ticket.

## Issue Found & Resolved

The dev server was returning 500 due to `String.replace(nil, ...)` on `@phone`. This was caused by a stale server process that predated the operator config addition — not a code bug. Restarting the server resolved it. The operator config in `config/config.exs` and the runtime override logic in `runtime.exs` are both correct.

## Test Coverage

This ticket's "tests" are the Playwright MCP verification steps documented in `progress.md`. They are agent-driven, not automated ExUnit tests. The landing page also has 11 existing ExUnit tests (per OVERVIEW.md) covering controller/template rendering.

**Coverage gaps:** None for this ticket's scope. Print layout verification (visual print preview) is not possible via accessibility snapshots — the tear-off strip and print-only elements are `hidden print:block` so they correctly don't appear in the screen-mode snapshot. Print rendering would require a print-to-PDF check, which is outside this ticket's scope.

## Open Concerns

1. **Print layout not browser-verified:** The print stylesheet (T-002-02) was verified during its own ticket. Playwright MCP can take screenshots but cannot trigger print preview or generate print PDFs to verify `@media print` rules. This is a known limitation, not a gap.

2. **Stale server risk:** The 500 error on first attempt was caused by a server started before config changes were committed. This is a dev workflow issue, not a code issue. `just dev` is idempotent but doesn't detect config staleness. Consider adding a config hash check to `just dev` if this recurs.

3. **No persistent browser tests:** This QA was agent-driven and not repeatable as `mix test`. If regression testing of the rendered page is desired, a Wallaby-based integration test suite would be a separate ticket.
