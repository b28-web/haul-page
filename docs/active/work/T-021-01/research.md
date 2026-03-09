# Research — T-021-01: QA Walkthrough Report

## What this ticket does

Capstone ticket: gather all browser-QA results, take fresh Playwright screenshots of the running app, and produce a walkthrough report (`walkthrough.md`) that briefs the developer on the state of the product.

## QA tickets surveyed (15 browser-QA tickets)

| Ticket | Area | Tests added | Bugs found | Status |
|--------|------|-------------|------------|--------|
| T-002-04 | Landing page | 0 (manual QA) | Stale dev config 500 | Fixed, pass |
| T-003-04 | Booking form | 0 (manual QA) | Missing tenant schema | Fixed, pass |
| T-005-04 | Scan page | 0 (manual QA) | Gallery fallback inconsistency | Pre-existing, pass |
| T-006-05 | Content domain | 0 (manual QA) | No markdown page route | N/A, pass |
| T-007-05 | Notifications | 0 (manual QA) | Oban startup fragility | Pre-existing, pass |
| T-008-04 | Payments | 0 (manual QA) | None | Pass |
| T-009-03 | Address autocomplete | 0 (manual QA) | Dropdown re-show after select | Minor UX, pass |
| T-012-05 | Tenant routing | 0 (manual QA) | Stale BEAM / migration | Pre-existing, pass |
| T-013-06 | Content admin | 0 (code fix) | LoginLive tenant key mismatch | Fixed in login_live.ex |
| T-014-03 | CLI onboarding | 10 tests | business_name not set by onboard | Known gap |
| T-015-04 | Self-service signup | 14 tests | Rate limiter ETS contamination | Fixed |
| T-016-04 | Billing | 16 tests | None | Pass |
| T-017-03 | Custom domains | 14 tests | None | Pass |
| T-019-06 | Chat onboarding | 25 tests | AppendMessage stale struct | Pre-existing |
| T-020-05 | AI provision pipeline | 14 tests | None | Pass |

## Existing screenshot artifacts

- T-003-04: desktop-1280x800.png, mobile-375x812.png
- T-005-04: desktop-full.png, mobile-full.png
- T-015-04: 7 PNGs (marketing, signup, dashboard, onboarding, mobile)

## Test count

Most recent full suite: **742 tests, 0 failures** (per T-020-05 review). 85 test files. ExUnit + LiveViewTest (no real browser Playwright tests — all QA uses LiveViewTest or MCP manual verification).

## Routes to screenshot

**Public pages:**
- `/` — landing (PageController, server-rendered)
- `/scan` — scan page (ScanLive)
- `/book` — booking form (BookingLive)
- `/scan/qr` — QR code (QRController)
- `/start` — chat onboarding (ChatLive)

**Admin pages (require auth):**
- `/app` — dashboard
- `/app/content/site` — site config
- `/app/content/services` — services list
- `/app/content/gallery` — gallery
- `/app/content/endorsements` — endorsements
- `/app/settings/billing` — billing
- `/app/settings/domain` — domain settings

**Signup/onboarding:**
- `/app/signup` — signup form
- `/app/login` — login

**Dev server:** port 4000, localhost

## Key constraints

- Playwright MCP screenshots are gitignored (*.png in work dirs)
- Dev server must be running with tenant provisioned and content seeded
- Stripe Payment Element iframe can't be automated (cross-origin)
- Subdomain/custom domain routing can't be tested via localhost
- Chat LLM features need BAML sandbox or mock
- Print media emulation available in Playwright

## Files relevant to report

- All `docs/active/work/T-*/progress.md` and `review.md` (surveyed above)
- `docs/active/OVERVIEW.md` — current status board
- `lib/haul_web/router.ex` — route definitions
- `test/` — 85 test files for coverage analysis
