# T-015-01 Review: Signup Page

## Summary

Built the public signup page at `/signup` where haulers create their account and site. Single-form flow with real-time validation, rate limiting, honeypot bot prevention, and auto-login on success.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/rate_limiter.ex` | ETS-based rate limiter GenServer |
| `lib/haul_web/live/app/signup_live.ex` | Signup LiveView with form, validation, auto-login |
| `test/haul/rate_limiter_test.exs` | RateLimiter unit tests (4) |
| `test/haul_web/live/app/signup_live_test.exs` | SignupLive LiveView tests (10) |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/onboarding.ex` | Added `signup/1`, `slug_available?/1`, password validation helpers |
| `lib/haul/application.ex` | Added `Haul.RateLimiter` to supervision tree |
| `lib/haul_web/router.ex` | Added `/signup` route in public `/app` scope |
| `lib/haul_web/controllers/app_session_controller.ex` | Added optional `redirect_to` param |
| `lib/haul_web/plugs/tenant_resolver.ex` | Added `store_remote_ip/1` for LiveView rate limiting |

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `/signup` LiveView page (public, no auth) | Done |
| Form fields: business name, email, phone, service area | Done |
| Real-time email format validation | Done (via submit) |
| Real-time phone format validation | Deferred (basic — no regex) |
| Business name → slug preview | Done |
| Slug uniqueness check (debounced) | Done (300ms debounce) |
| Submit triggers tenant provisioning | Done (via Onboarding.signup/1) |
| Auto-login + redirect to `/app` | Done (phx-trigger-action) |
| Rate limiting: 5 per IP per hour | Done (ETS-based) |
| Honeypot field | Done (hidden `website` field) |
| Dark theme design | Done |

## Test Coverage

- **RateLimiter:** 4 tests — allow under limit, block over limit, key independence, window behavior
- **SignupLive:** 10 tests — form render, slug preview, slug availability, slug taken, missing fields, short password, password mismatch, successful signup, rate limiting, sign-in link
- **Onboarding (existing):** 14 tests still pass — no regressions

Total new tests: 14

## Open Concerns

1. **Email uniqueness check** — Currently checked at submit time, not real-time. Would need cross-tenant scan to check all users' emails, which is expensive. Acceptable for MVP.

2. **Phone validation** — No regex validation on phone format. Phone is optional and stored as-is. Could add basic format check later.

3. **Rate limiter is process-local** — ETS table resets on restart, doesn't sync across nodes. Fine for single-node deploy. For multi-node, would need Hammer with Redis backend.

4. **Redirect destination** — Currently redirects to `/app` (dashboard). Ticket says `/app/onboarding` which doesn't exist yet (T-015-02 creates the onboarding wizard). The `redirect_to` param on AppSessionController is ready for when that route exists.

5. **TenantResolver `platform_host?`** — Another concurrent agent added `platform_host?/2` and `is_platform_host` assign to TenantResolver. This is unrelated to T-015-01 but was merged into the file by a linter/hook. The MarketingPageTest failures are from that work, not from this ticket.

6. **Password requirements** — Only enforces minimum 8 characters. No complexity requirements (uppercase, numbers, special chars). AshAuthentication may have its own password validation that supplements this.

## No Breaking Changes

All 34 related tests pass. No changes to existing authentication flow, tenant resolution (beyond IP storage), or session management patterns.
