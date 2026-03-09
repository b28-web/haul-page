# T-015-04 Design: Browser QA — Self-Service Signup Flow

## Approach

**Chosen: Dual-layer testing — ExUnit integration tests + Playwright MCP browser verification**

### Option A: Playwright MCP only
- Pros: True browser testing, visual verification, screenshots
- Cons: Requires running dev server, flaky with timing, can't easily verify DB state, hard to automate in CI
- **Rejected**: Too fragile for the primary test suite, but valuable for visual verification

### Option B: ExUnit integration tests only
- Pros: Fast, deterministic, CI-friendly, can verify DB state
- Cons: No actual browser rendering, no visual verification, no mobile viewport testing
- **Rejected**: Misses the visual/browser verification that the ticket explicitly requires

### Option C: Both (chosen)
- ExUnit integration test that exercises the full signup-to-onboarding flow end-to-end
- Playwright MCP session for visual verification, screenshots, mobile testing
- **Why**: ExUnit tests provide reliable regression coverage. Playwright provides the visual QA and mobile checks the ticket demands.

## ExUnit Test Design

### New test file: `test/haul_web/live/app/signup_flow_test.exs`

End-to-end integration test covering the complete journey:

1. **Marketing page → signup link**: GET `/` on bare domain, verify CTA links to `/app/signup`
2. **Signup form completion**: Mount SignupLive, fill all fields, submit, verify `phx-trigger-action`
3. **Session establishment**: POST to `/app/session` with token+tenant, follow redirect
4. **Onboarding wizard walkthrough**: Navigate all 6 steps, verify content at each
5. **Go live**: Click "Launch My Site", verify `onboarding_complete` flag, verify redirect
6. **Tenant site renders**: GET `/` on tenant subdomain, verify operator content appears
7. **Validation edge cases**: Missing fields, short password, password mismatch

### Why not extend existing tests?
- `signup_live_test.exs` tests the signup form in isolation — doesn't follow through to session/onboarding
- `onboarding_live_test.exs` uses `create_authenticated_context()` helper — bypasses signup entirely
- The gap is the connected flow: signup → auto-login → onboarding → live site

## Playwright MCP Session Design

Interactive browser verification:
1. Navigate to marketing page, screenshot
2. Click CTA, verify signup page loads
3. Fill form with test data, screenshot slug preview
4. Submit, wait for redirect to onboarding
5. Step through wizard, screenshot each step
6. Mobile viewport (375x812): repeat signup form + wizard
7. Verify pricing section renders correctly

## Test Data

- Business: "QA Test Hauling"
- Email: "qa-test@example.com"
- Phone: "555-0123"
- Area: "Seattle, WA"
- Password: "TestPassword123!"
- Expected slug: "qa-test-hauling"

## Timing

The ticket asks to measure signup-to-live-site time. We'll log timestamps at key transitions in the ExUnit test.
