# T-015-04 Research: Browser QA — Self-Service Signup Flow

## Scope

Playwright MCP verification of the full self-service signup flow: marketing page → signup → onboarding wizard → live site. This is the critical SaaS acquisition journey.

## Dependencies (all complete)

- **T-015-01** (signup page): SignupLive at `/app/signup` with real-time slug preview, validation, rate limiting
- **T-015-02** (onboarding wizard): OnboardingLive at `/app/onboarding` with 6-step wizard
- **T-015-03** (marketing landing): Marketing page at `/` on bare domain with pricing, features, CTAs

## Routes & Flow

```
GET / (bare domain, haulpage.test) → Marketing page (PageController.home, is_platform_host=true)
  ↓ "Get Started Free" link
GET /app/signup → SignupLive (no auth required)
  ↓ successful signup → phx-trigger-action POSTs hidden form
POST /app/session → AppSessionController.create (sets JWT + tenant session)
  ↓ redirect
GET /app/onboarding → OnboardingLive (requires auth, 6-step wizard)
  ↓ complete wizard → "Launch My Site" → onboarding_complete=true
GET /app → DashboardLive (redirect target after wizard)
```

## Key Components

### Marketing Page (`page_html/marketing.html.heex`)
- Rendered by PageController.home when `is_platform_host` is true
- Sections: Nav, Hero, Features (6 cards), How It Works (3 steps), Pricing (4 tiers), Footer
- CTA links to `/app/signup` ("Get Started Free", "Start Free", tier buttons)

### SignupLive (`live/app/signup_live.ex`)
- Form fields: Business Name, Email, Phone, Service Area, Password, Password Confirmation
- Hidden honeypot "website" field
- Real-time slug preview with availability check (`Onboarding.slug_available?`)
- Rate limiting: 5 signups per IP per hour via `RateLimiter`
- On success: sets hidden `token` + `tenant` fields, triggers form POST to `/app/session`

### AppSessionController (`controllers/app_session_controller.ex`)
- POST `/app/session`: reads `session[token]` and `session[tenant]`, sets session cookies
- Redirects to `/app` (or `redirect_to` param)

### OnboardingLive (`live/app/onboarding_live.ex`)
- 6 steps: Confirm Info → Your Site → Services → Upload Logo → Preview → Go Live
- Step 1: Ash form for SiteConfig (business_name, phone, email, service_area)
- Step 2: Shows subdomain URL
- Step 3: Shows seeded default services
- Step 4: Logo upload (LiveView upload, max 5MB)
- Step 5: Preview with "Open Site in New Tab" link
- Step 6: "Launch My Site" → sets `onboarding_complete: true`, redirects to `/app`

### TenantResolver (`plugs/tenant_resolver.ex`)
- Sets `is_platform_host` for bare domain detection
- Resolves tenant from subdomain or custom domain
- Stores `tenant_slug` and `remote_ip` in session

## Existing Test Coverage

### Unit/Integration Tests (already exist, not browser QA)
- `signup_live_test.exs` — 8 tests: form render, slug preview, availability, validation errors, successful signup, rate limiting, sign-in link
- `onboarding_live_test.exs` — 10 tests: auth redirect, step navigation, step content, go-live redirect
- `marketing_page_test.exs` — 7 tests: page render, pricing, features, CTAs, how-it-works, no operator content, title
- `onboarding_qa_test.exs` — 8 tests: CLI onboarding → page verification (different from signup flow)

### What Existing Tests DON'T Cover
- **End-to-end flow**: No test goes marketing → signup → session → onboarding → live site
- **Playwright browser verification**: No actual browser rendering, screenshots, or visual checks
- **Mobile viewport**: No responsive testing
- **Timing measurement**: No signup-to-live-site timing
- **Cross-page navigation**: No test follows the actual redirect chain

## Test Infrastructure

- **Playwright MCP** available via `.mcp.json` config
- **Dev server** at localhost:4000
- **Marketing page host**: Must use bare domain (e.g., `localhost:4000` without subdomain) or configure `is_platform_host`
- **Tenant isolation**: Each signup creates a new tenant schema
- **Authentication**: JWT token in session, set via AppSessionController

## Constraints

- Rate limiter (5/hr/IP) could interfere with repeated test runs
- Tenant provisioning creates real DB schemas — cleanup needed
- Playwright screenshots are gitignored (walkthrough-*.png pattern)
- Dev server must be running for Playwright MCP tests
- Marketing page requires bare domain host detection
