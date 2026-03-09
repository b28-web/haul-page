# T-015-04 Progress: Browser QA — Self-Service Signup Flow

## Completed

### Step 1: ExUnit integration tests
- Created `test/haul_web/live/app/signup_flow_test.exs` — 14 tests
- Marketing page verification (CTAs, pricing, features, how-it-works)
- Signup form validation (slug preview, required fields, password rules)
- Full signup flow: form → session → company + tenant + content verification
- Onboarding wizard walkthrough: all 6 steps, go-live, onboarding_complete flag
- Tenant site rendering after signup (operator content visible)
- Timing measurement: signup ~320ms, total to live ~370ms

### Step 2: Rate limiter fix
- Added `clear_rate_limits/0` helper to `test/support/conn_case.ex`
- Applied to both `signup_flow_test.exs` and `signup_live_test.exs` setup blocks
- Fixed cross-test ETS contamination that caused rate limit failures when test files ran together

### Step 3: Full test suite
- 396 tests, 0 failures (up from 382 before this ticket — 14 new tests added)

### Step 4: Playwright MCP browser verification
- Marketing page: full-page screenshot, all sections present, CTAs link to /app/signup
- Signup form: filled all fields, slug preview "qa-test-hauling.localhost Available" shown
- Form submission: auto-login via POST /app/session → redirect to /app dashboard
- Onboarding wizard: navigated all 6 steps, "Launch My Site" → dashboard with "Your site is live!"
- Mobile viewport (375x812): signup form and marketing page both fully responsive
- Screenshots saved to docs/active/work/T-015-04/

## Deviations from plan

- First Playwright signup attempt crashed because the dev server had stopped (port conflict from test suite). Restarted server and retried successfully.
- Signup redirects to /app (dashboard) not /app/onboarding — the auto-redirect to onboarding only happens if the app explicitly routes there. This is correct behavior; the user navigates to onboarding from the dashboard or sidebar.
