# T-013-06 Design: Browser QA for Content Admin UI

## Approach

Browser QA via Playwright MCP against localhost:4000, following the same pattern as T-012-05, T-002-04, and other completed browser QA tickets. No production code changes — this is verification only.

## Test Strategy

### Option A: Playwright MCP Only (Selected)

Walk through the admin UI using Playwright MCP tools:
1. Navigate to `/app` → verify redirect to login
2. Fill login form with seeded credentials → authenticate
3. Navigate each admin page → verify content loads
4. Edit SiteConfig → verify change persists on public page
5. Check mobile layout

**Pros:** Matches ticket requirements exactly. End-to-end browser verification.
**Cons:** Depends on dev server state and seeded data.

### Option B: ExUnit LiveView Tests + Playwright

Add ExUnit tests alongside Playwright verification.
**Rejected:** ExUnit tests already exist for each LiveView (6 test files). Playwright MCP is the specific verification requested.

### Option C: Playwright Codegen Script

Write a standalone Playwright test script.
**Rejected:** Previous QA tickets used Playwright MCP interactively, not scripts. Consistency matters.

## Authentication Challenge

Playwright MCP must authenticate to access `/app/*` routes. The login flow:
1. Navigate to `/app/login`
2. Fill email + password fields
3. Submit form → server sets session cookie → redirect to `/app`

The session cookie persists across Playwright navigations within the same browser context. This is the standard approach used by other browser QA tickets.

## Seeded Data Prerequisites

Default operator `junk-and-handy` should have:
- Company + User (from seed task)
- SiteConfig with business details
- Services (6 default)
- GalleryItems (3 default before/after pairs)
- Endorsements (4 default testimonials)

Login credentials: from the seed task — need to verify what email/password are used.

## Verification Sequence

1. **Unauthenticated redirect** — `/app` → redirected to `/app/login`
2. **Login** — Fill form, submit, verify redirect to dashboard
3. **Dashboard** — Company name, site URL visible
4. **SiteConfig** — Form loads with current values, edit tagline, save, verify flash
5. **Public page check** — Navigate to `/`, verify updated tagline
6. **Services** — List loads with service items
7. **Gallery** — Grid loads with gallery items
8. **Endorsements** — List loads with endorsement items
9. **Mobile** — Resize to 375×812, verify hamburger menu, navigate via mobile nav

## What "Pass" Looks Like

Each step verified via `browser_snapshot` accessibility tree:
- Correct headings and labels present
- Form fields populated with expected data
- Navigation links functional
- Flash messages appear after saves
- Content changes reflected on public pages
- Mobile layout shows hamburger instead of sidebar

## Risk

- If seeded data is missing or stale, steps will fail. Mitigation: verify data exists before starting.
- If login credentials are wrong, auth steps fail. Mitigation: check seed task for credentials.
