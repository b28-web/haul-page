# T-015-01 Design: Signup Page

## Decision Summary

Build a public LiveView at `/signup` with real-time validation, honeypot bot prevention, ETS-based rate limiting, and auto-login on success via controller POST (same pattern as LoginLive).

## Approach: Extend Onboarding Module

**Option A: Call `Haul.Onboarding.run/1` directly from LiveView**
- Pro: Reuse existing logic
- Con: `run/1` generates temp password, doesn't accept user-provided password
- Con: No granular error handling for form validation

**Option B: New `Haul.Onboarding.signup/1` function**
- Pro: Accepts password, returns token for auto-login
- Pro: Better error messages for form context
- Pro: Reuses internal helpers from Onboarding
- Con: Minor duplication

**Decision: Option B.** Add `signup/1` to `Haul.Onboarding` that accepts password/password_confirmation and returns the user with token metadata. Internally reuses `find_or_create_company`, `seed_content`, `update_site_config`. Differs from `run/1` only in user creation (user-provided password, returns token).

## Form Design

### Fields
1. **Business name** (required) — text input, derives slug live
2. **Email** (required) — email input, checks uniqueness
3. **Phone** (optional) — tel input
4. **Service area** (optional) — text input
5. **Password** (required) — password input, min 8 chars
6. **Password confirmation** (required) — must match
7. **Honeypot** (`website` field, hidden via CSS)

### Real-Time Validation
- `phx-change="validate"` on form
- Business name change → derive slug → show preview "Your site: {slug}.{base_domain}"
- Slug uniqueness: debounced check via `phx-debounce="500"` on business name input
- Email format: basic regex in changeset
- Email uniqueness: check across all tenants' users (expensive — defer to submit)
- Phone: basic format validation

### Slug Preview
Server-side slug derivation on every `validate` event. Show below business name:
"Your site: **joes-hauling.haulpage.com**" with availability indicator.

## Rate Limiting

**Decision: ETS-based counter module `Haul.RateLimiter`**
- GenServer owning an ETS table
- `check_rate(key, limit, window_ms)` → `:ok | {:error, :rate_limited}`
- Key: `{:signup, ip_string}`
- Limit: 5 per hour (3600 seconds)
- Started in Application supervision tree
- No external deps

Why not Hammer/ExRated: Adds a dependency for one use case. ETS is sufficient for single-node. Can upgrade when needed.

## Auto-Login Flow

Same pattern as LoginLive:
1. On successful signup, get user token from `user.__metadata__.token`
2. Stuff token + tenant into hidden form fields
3. Set `trigger_submit = true` → `phx-trigger-action` POSTs to controller
4. Extend `AppSessionController.create` to handle signup redirect (optional param)

For redirect: signup POST goes to same `/app/session` endpoint. Controller redirects to `/app` (or `/app/onboarding` when T-015-02 adds it).

## Bot Prevention

Hidden `website` field with `aria-hidden="true"` and CSS positioning off-screen.
- If non-empty on submit → silently return success (don't reveal detection)
- Bots fill all visible fields; real users never see this field

## Error Handling

- **Slug taken:** "This site name is already taken. Try a different business name."
- **Email taken:** "An account with this email already exists. Try signing in."
- **Provisioning failure:** "Something went wrong creating your site. Please try again."
- **Rate limited:** "Too many signup attempts. Please try again in an hour."
- **Validation errors:** Inline per-field via Ash changeset errors

## Layout

No admin layout — standalone page like LoginLive. Dark theme, centered card.

Header: "Get your hauling site live in 2 minutes"
Subtext: "Free to start. No credit card required."
CTA button: "Create My Site"

## Rejected Alternatives

1. **Email verification before provisioning** — too much friction for MVP. Can add later.
2. **Multi-step wizard on signup** — that's T-015-02. Signup is single form.
3. **Hammer dependency** — overkill for one rate limit check.
4. **Client-side slug derivation** — would need JS hook to match Elixir regex. Server-side is simpler and authoritative.
