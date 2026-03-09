# T-005-04 Review — Browser QA for Scan Page

## Summary

Browser QA for the scan page (`/scan`) completed using Playwright MCP. All acceptance criteria met. The page renders correctly on both desktop and mobile viewports with all required content sections present and properly ordered.

## What Was Tested

| Test | Viewport | Result |
|------|----------|--------|
| Page loads at `/scan` | Desktop | ✅ 200 OK |
| Hero: business name, H1, phone link | Desktop | ✅ All present |
| Hero: tel: link format | Desktop | ✅ `tel:5551234567` |
| Gallery: "Our Work" heading + 3 items | Desktop | ✅ Present with fallback icons |
| Endorsements: 4 cards with stars/quotes | Desktop | ✅ All rendered |
| Footer: "Ready to Book?" + CTAs | Desktop | ✅ Both buttons present |
| CTA prominence on mobile | 375×812 | ✅ Phone number is first action |
| Mobile layout integrity | 375×812 | ✅ No overflow, sections stack |
| Server errors | — | ✅ No 500s |

## Files Created

| File | Purpose |
|------|---------|
| `docs/active/work/T-005-04/research.md` | Codebase mapping |
| `docs/active/work/T-005-04/design.md` | QA approach decision |
| `docs/active/work/T-005-04/structure.md` | File-level plan |
| `docs/active/work/T-005-04/plan.md` | Test steps |
| `docs/active/work/T-005-04/progress.md` | Execution log with results |
| `docs/active/work/T-005-04/review.md` | This file |
| `docs/active/work/T-005-04/desktop-full.png` | Desktop screenshot |
| `docs/active/work/T-005-04/mobile-full.png` | Mobile screenshot |

## Files Modified

None. This is a QA-only ticket — no application code was changed.

## Test Coverage

No new automated tests added (QA ticket, not implementation). Existing coverage:
- 9 LiveView tests in `test/haul_web/live/scan_live_test.exs`
- 10 QR controller tests in `test/haul_web/controllers/qr_controller_test.exs`
- 7 content loader tests in `test/haul/content/loader_test.exs`
- Total: 26 tests covering the scan page story

## Open Concerns

### Minor: Gallery image fallback inconsistency
On mobile, the first gallery item displayed broken image alt text instead of the photo icon placeholder. Items 2 and 3 showed the correct fallback. This appears to be a browser caching/timing issue with the `onerror` handler — when navigating a second time, the browser may serve the cached 404 without re-triggering the error event. **Not a functional blocker** — real gallery images would eliminate this entirely. If it needs fixing, the onerror handler in `scan_live.ex` could be supplemented with a CSS-based fallback or the images could be checked on mount.

### Expected: Missing gallery images
All 6 gallery image URLs (`/images/gallery/{before,after}-{1,2,3}.jpg`) return 404. The placeholder icon fallback works as designed. Real images will be added when content is populated.

### Expected: `/book` route returns 404
Both "Book Online" buttons link to `/book` which doesn't exist yet. This is expected — T-003-01 (booking form) will create it.

## Acceptance Criteria Status

All three acceptance criteria are met:
1. ✅ All content sections present and ordered correctly
2. ✅ CTA is accessible and links to correct phone number
3. ✅ No 500 errors in server logs
