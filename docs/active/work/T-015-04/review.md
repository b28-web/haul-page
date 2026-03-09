# T-015-04 Review: Browser QA — Self-Service Signup Flow

## Summary

Complete browser QA verification of the self-service signup flow: marketing page → signup → onboarding wizard → live site. Both ExUnit integration tests and Playwright MCP browser verification confirm the flow works end-to-end.

## Files Changed

### Created
- `test/haul_web/live/app/signup_flow_test.exs` — 14 end-to-end integration tests

### Modified
- `test/support/conn_case.ex` — Added `clear_rate_limits/0` helper to prevent cross-test ETS contamination
- `test/haul_web/live/app/signup_live_test.exs` — Added `clear_rate_limits()` call in setup

### Artifacts (gitignored screenshots)
- `docs/active/work/T-015-04/marketing-page.png` — Full marketing page
- `docs/active/work/T-015-04/signup-filled.png` — Signup form with slug preview
- `docs/active/work/T-015-04/dashboard-after-signup.png` — Dashboard after successful signup
- `docs/active/work/T-015-04/onboarding-step1.png` — Wizard step 1 with pre-filled data
- `docs/active/work/T-015-04/onboarding-step6.png` — Wizard step 6 go-live
- `docs/active/work/T-015-04/mobile-signup.png` — Mobile viewport signup form
- `docs/active/work/T-015-04/mobile-marketing.png` — Mobile viewport marketing page

## Test Coverage

### New tests (14 total in signup_flow_test.exs)
| Test | What it verifies |
|------|-----------------|
| Marketing page CTAs | Bare domain renders marketing page with "Get Started Free" linking to /app/signup |
| Pricing tiers | Starter/Free, Pro/$29, Business/$79 present |
| Features section | Professional Website, Online Booking, Mobile Ready |
| How-it-works section | Sign Up, Customize, Get Customers |
| Form fields | All 6 fields render (name, email, phone, area, password, confirm) |
| Slug preview | "qa-test-hauling" preview with "Your site:" label |
| Slug availability | Shows "Available" for unused slug |
| Missing name validation | Shows "name is required" error |
| Short password validation | Shows "password must be at least 8 characters" |
| Password mismatch | Shows "passwords do not match" |
| Signup creates resources | Company, tenant schema, SiteConfig, services, gallery, endorsements all created |
| Onboarding wizard walkthrough | Steps 1-6, go-live sets onboarding_complete, redirects to /app |
| Tenant site renders | Operator content (phone, email, area, services) visible on tenant home |
| Sign-in link | "Already have an account?" with /app/login link |

### Timing measurements
- Signup (form submit → company + content created): ~320ms
- Total to live (signup + wizard walkthrough): ~370ms

### Full suite: 396 tests, 0 failures

## Playwright Browser Verification Results

All acceptance criteria verified:

1. **Marketing page** — Professional landing page with hero, features (6 cards), how-it-works (3 steps), pricing (4 tiers), clear CTAs
2. **Signup form** — All fields present, real-time slug preview with availability indicator ("Available" in green)
3. **Form submission** — Auto-login via hidden form POST to /app/session, redirect to dashboard
4. **Onboarding wizard** — 6-step wizard with progress bar, pre-filled data from signup, step navigation works
5. **Go live** — "Launch My Site" sets onboarding_complete, redirects to dashboard with "Your site is live!" flash
6. **Mobile** — Both signup form and marketing page fully responsive at 375x812

## Bug Found & Fixed

**Rate limiter ETS contamination**: When `signup_live_test.exs` (which includes a rate-limit exhaustion test) ran before `signup_flow_test.exs`, the ETS entries persisted and caused subsequent signup submissions to be rate-limited. Fixed by adding `clear_rate_limits/0` helper to ConnCase and calling it in setup blocks of both test files.

## Open Concerns

1. **Post-signup redirect**: Signup redirects to `/app` (dashboard), not `/app/onboarding`. The onboarding wizard is accessed by navigating to it. Consider adding auto-redirect to onboarding for new signups with `onboarding_complete == false` — but this is a UX decision, not a bug.
2. **Onboarding step 1 business name**: Shows "Your Business Name" (default from SiteConfig) rather than the actual business name entered during signup. The phone, email, and service area are correctly pre-filled. This is a minor SiteConfig seeding issue — the business_name field in SiteConfig defaults to a generic value rather than inheriting from signup.
3. **Subdomain testing limitation**: Can't navigate to `qa-test-hauling.localhost` in Playwright because the browser resolves localhost subdomains differently. The ExUnit tests verify tenant content rendering by overriding the operator config instead.
