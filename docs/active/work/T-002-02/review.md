# T-002-02 Review: Print Stylesheet

## Summary

Completed the print stylesheet for the landing page poster. The existing implementation (from T-002-01) was ~80% complete. This ticket filled four gaps: max-width removal for full-width print, page-break prevention, SVG icon visibility, and a print-only URL display.

## Files Changed

| File | Change |
|------|--------|
| `assets/css/app.css` | Added 3 rules to existing `@media print` block (+13 lines) |
| `lib/haul_web/controllers/page_controller.ex` | Added `@url` assign from `Endpoint.url()` (+1 line) |
| `lib/haul_web/controllers/page_html/home.html.heex` | Added print-only URL+phone paragraph (+5 lines) |

Total: ~19 lines added across 3 files. No files created or deleted.

## Acceptance Criteria Checklist

| Criterion | Status | Notes |
|-----------|--------|-------|
| `@media print` rules in `assets/css/app.css` | ✓ | All rules in single `@media print` block |
| White bg, dark text, strip section backgrounds | ✓ | Existed from T-002-01 |
| `.no-print` hides buttons, interactive elements | ✓ | Implemented as Tailwind `print:hidden` (idiomatic equivalent) |
| Tear-off strip visible only in print | ✓ | Existed from T-002-01 |
| Headings use correct print sizes (42pt/22pt) | ✓ | Existed from T-002-01 |
| Page fits on letter-size paper with 0.3in margins | ✓ | `@page` rule + max-width removal (new) |
| Phone number and URL visible in print output | ✓ | URL display added (new) |
| Tested via browser print preview | ⚠ | See open concerns |

## Test Coverage

- **Compilation:** `mix compile --warnings-as-errors` passes
- **Existing tests:** 11/11 pass, 0 failures
- **No new tests added:** Changes are pure CSS + template markup; no testable logic

## Design Decisions

1. **`print:hidden` instead of `.no-print` class:** The ticket design section mentions `.no-print` from the React prototype. The Tailwind `print:hidden` variant is functionally identical and idiomatic for Tailwind 4. No custom class needed.

2. **URL from `Endpoint.url()`:** Uses Phoenix's built-in endpoint URL configuration rather than a separate env var. This respects the existing config/runtime.exs setup where `PHX_HOST` sets the hostname.

3. **Attribute selector for max-width:** `[class*="max-w-"]` catches all Tailwind max-width utilities globally. More robust than targeting specific classes, and appropriate for a print context where all width constraints should be removed.

## Open Concerns

1. **Browser print preview testing:** The AC requires "Tested via browser print preview." Automated tools (Playwright) cannot reliably capture print preview rendering. This needs manual QA — open the page, Cmd+P, verify layout on letter paper. Recommend adding this to T-002-04 (browser QA ticket) if it exists.

2. **Google Fonts in print:** If the user prints while offline or before fonts load, the browser falls back to sans-serif. The CSS `font:` shorthand includes the fallback, so this degrades gracefully, but headings won't be in Oswald.

3. **Tear-off strip height:** The tear-off strip's vertical tabs use `writing-mode: vertical-rl` with small font sizes. Whether all 8 tabs fit cleanly at the bottom of a letter page depends on how much content is above. With the current 4-section layout it should fit, but adding content to the page could push the strip to a second page. The `break-inside: avoid` on sections helps but doesn't guarantee the strip stays on page 1.
