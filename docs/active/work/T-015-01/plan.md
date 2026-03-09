# T-015-01 Plan: Signup Page

## Step 1: RateLimiter Module

Create `lib/haul/rate_limiter.ex` — GenServer with ETS table.
Create `test/haul/rate_limiter_test.exs` — unit tests.
Add to supervision tree in `lib/haul/application.ex`.

Verify: `mix test test/haul/rate_limiter_test.exs`

## Step 2: Extend Onboarding Module

Add to `lib/haul/onboarding.ex`:
- `signup/1` — like `run/1` but accepts password, returns user with token
- `slug_available?/1` — checks Company slug uniqueness

Verify: `mix test test/haul/onboarding_test.exs`

## Step 3: Router + Session Controller

Modify `lib/haul_web/router.ex`:
- Add `live "/signup", App.SignupLive` in public `/app` scope

Modify `lib/haul_web/controllers/app_session_controller.ex`:
- Support optional `redirect_to` param

Modify `lib/haul_web/plugs/tenant_resolver.ex`:
- Store remote_ip string in session for LiveView rate limiting

## Step 4: SignupLive LiveView

Create `lib/haul_web/live/app/signup_live.ex`:
- Form with business name, email, phone, service area, password, password_confirmation
- Honeypot field (hidden `website`)
- Real-time slug preview with availability check
- Rate limiting on submit
- Auto-login via phx-trigger-action POST to session controller

## Step 5: SignupLive Tests

Create `test/haul_web/live/app/signup_live_test.exs`:
- Page renders with form fields
- Slug preview updates on business name change
- Validation errors shown for missing/invalid fields
- Successful signup creates company + tenant + user
- Honeypot blocks bots
- Rate limiting blocks excessive signups
- Duplicate slug shows error

## Testing Strategy

- **Unit tests:** RateLimiter (allow/block/expiry), Onboarding.signup (success/validation errors)
- **LiveView tests:** Form rendering, validation feedback, successful flow, error cases
- **No browser QA** — that's T-015-04
