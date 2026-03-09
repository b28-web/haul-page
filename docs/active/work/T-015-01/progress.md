# T-015-01 Progress: Signup Page

## Completed

### Step 1: RateLimiter Module
- Created `lib/haul/rate_limiter.ex` — GenServer + ETS-based rate limiter
- Created `test/haul/rate_limiter_test.exs` — 4 unit tests
- Added to supervision tree in `lib/haul/application.ex`
- All tests pass

### Step 2: Extend Onboarding Module
- Added `signup/1` to `lib/haul/onboarding.ex` — accepts password, returns user with JWT token
- Added `slug_available?/1` for real-time slug checking
- Added password validation helpers (length, match)
- Added `create_signup_owner/5` — creates user with provided password, preserves token metadata
- Existing onboarding tests still pass (14 tests)

### Step 3: Router + Session Controller
- Added `live "/signup", App.SignupLive` to public `/app` scope in router
- Extended `AppSessionController.create` to support optional `redirect_to` param
- Added `store_remote_ip/1` to TenantResolver plug for rate limiting in LiveView

### Step 4: SignupLive LiveView
- Created `lib/haul_web/live/app/signup_live.ex`
- Form fields: business name, email, phone, service area, password, password_confirmation
- Honeypot field (hidden `website` input)
- Real-time slug preview with availability indicator (Available/Taken)
- Rate limiting on submit (5 per IP per hour)
- Auto-login via phx-trigger-action POST to session controller
- Dark theme, centered card layout, sign-in link

### Step 5: Tests
- Created `test/haul_web/live/app/signup_live_test.exs` — 10 tests
- Renders form, slug preview, slug availability, validation errors, successful signup, rate limiting, sign-in link

## Test Results
- 34 related tests: 0 failures
- All pre-existing tests unaffected (MarketingPage failures are from concurrent agent work)
