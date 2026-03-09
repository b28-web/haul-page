# T-015-01 Structure: Signup Page

## Files Created

### `lib/haul/rate_limiter.ex`
GenServer + ETS-based rate limiter.
- `start_link/1` — starts GenServer, creates ETS table
- `check_rate(key, limit, window_seconds)` → `:ok | {:error, :rate_limited}`
- Periodic cleanup of expired entries (every 60s)
- Supervised in `Haul.Application`

### `lib/haul_web/live/app/signup_live.ex`
Public LiveView at `/signup`.
- `mount/3` — init form assigns, get IP from session, get base_domain
- `render/1` — signup form with real-time slug preview
- `handle_event("validate", ...)` — validate form, derive slug, check availability
- `handle_event("submit", ...)` — rate limit check, honeypot check, call Onboarding.signup
- Assigns: form (map-based), slug, slug_available, base_domain, trigger_submit, submitting

### `test/haul_web/live/app/signup_live_test.exs`
LiveView tests for signup flow:
- Renders form
- Real-time slug derivation and preview
- Validation errors (missing fields, short password)
- Successful signup creates company + user
- Honeypot rejection
- Rate limiting
- Slug uniqueness feedback

### `test/haul/rate_limiter_test.exs`
Unit tests for rate limiter:
- Allows requests under limit
- Blocks requests over limit
- Resets after window expires

## Files Modified

### `lib/haul/onboarding.ex`
Add `signup/1` function:
- Accepts: name, email, phone, area, password, password_confirmation
- Same pipeline as `run/1` but uses provided password
- Returns `{:ok, %{company, tenant, user, content}}` where user has token in metadata
- Does NOT call `find_or_create_owner` — creates fresh user with password

### `lib/haul/application.ex`
Add `Haul.RateLimiter` to supervision tree.

### `lib/haul_web/router.ex`
Add `live "/signup", App.SignupLive` to public `/app` scope.

### `lib/haul_web/controllers/app_session_controller.ex`
Add `redirect_to` param support — if present, redirect there instead of `/app`.
For signup: redirect to `/app` (later `/app/onboarding`).

### `lib/haul_web/plugs/tenant_resolver.ex`
Store `remote_ip` in session for LiveView access (needed for rate limiting).

## Module Boundaries

```
SignupLive (presentation)
  → Haul.Onboarding.signup/1 (orchestration)
    → Company.create_company (tenant creation + provisioning)
    → Seeder.seed! (content)
    → SiteConfig update
    → User.register_with_password (with provided password)
  → Haul.RateLimiter.check_rate/3 (rate limiting)
  → AppSessionController.create (session + redirect)
```

## Public Interfaces

### `Haul.Onboarding.signup/1`
```elixir
@spec signup(map()) :: {:ok, result()} | {:error, atom(), term()}
def signup(%{name: _, email: _, password: _, password_confirmation: _} = params)
```

### `Haul.RateLimiter`
```elixir
@spec check_rate(term(), pos_integer(), pos_integer()) :: :ok | {:error, :rate_limited}
def check_rate(key, limit, window_seconds)
```

### `Haul.Onboarding.slug_available?/1`
```elixir
@spec slug_available?(String.t()) :: boolean()
def slug_available?(slug)
```

## No Changes To

- Company resource (slug derivation already in create_company action)
- User resource (register_with_password already works)
- TenantHook (signup doesn't use it)
- AuthHooks (signup is pre-auth)
- Content resources
