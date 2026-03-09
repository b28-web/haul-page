# T-013-06 Progress — Browser QA for Content Admin UI

## Prerequisites

- Dev server: running on port 4000
- Playwright MCP: connected (headless Chrome)
- Tenant: default operator `junk-and-handy` with seeded content
- User created: admin@example.com / Password123! (owner role)
- Pending migration applied: `sort_order` column added to endorsements
- Gallery versions FK constraint dropped (PaperTrail fix)

## Bug Found & Fixed

**LoginLive tenant resolution bug:** `LoginLive.mount/3` read `session["tenant"]` but TenantResolver writes `session["tenant_slug"]`. Login always failed because `sign_in_with_password` received `tenant: nil`, so it couldn't find users in the tenant schema.

**Fix:** Updated `login_live.ex` mount to also check `session["tenant_slug"]` and convert via `ProvisionTenant.tenant_schema/1`.

## Step 1: Unauthenticated Redirect — PASS

- Navigated to `http://localhost:4000/app`
- Redirected to `/app/login`
- Login form rendered with Email/Password fields and "Sign In" heading

## Step 2: Authentication — PASS

- Filled email: admin@example.com, password: Password123!
- Submitted form → redirected to `/app` dashboard
- Page title: "Dashboard · Phoenix Framework"

## Step 3: Dashboard Verification — PASS

- Company name: "Junk & Handy" in header
- User email: "admin@example.com" displayed
- Site URL: "https://junk-and-handy.localhost" with link
- Sidebar nav: Dashboard, Content, Bookings, Settings

## Step 4: SiteConfig Form — PASS

- Navigated to `/app/content/site`
- Form loaded with all fields populated:
  - Business Name: "Junk & Handy"
  - Tagline: "We haul it all — fast, fair, and friendly."
  - Phone: "(555) 123-4567"
  - Email: "hello@junkandhandy.com"
  - Address, Service Area, Primary Color, Coupon Text, Meta Description
- Content submenu expanded: Site Settings, Services, Gallery, Endorsements

## Step 5: SiteConfig Edit + Save — PASS

- Changed tagline to "QA-verified: We haul it all!"
- Clicked "Save Settings"
- Flash message: "Site settings updated"
- Tagline field shows updated value

## Step 6: Public Page Verification — PASS

- Navigated to `http://localhost:4000/`
- Updated tagline "QA-verified: We haul it all!" visible on landing page
- Confirmed content changes reflect immediately
- Restored original tagline afterward

## Step 7: Services Page — PASS

- Navigated to `/app/content/services`
- 6 services rendered with titles, descriptions:
  1. Junk Removal
  2. Furniture Pickup
  3. Appliance Hauling
  4. Yard Waste
  5. Construction Debris
  6. Estate Cleanout
- Edit/Delete buttons on each, Move up/down for reordering
- "Add Service" button present

## Step 8: Gallery Page — PASS

- Navigated to `/app/content/gallery`
- 6 gallery items with before/after image pairs
- Captions, Featured badges, alt text on images
- Action buttons: Move up/down, Deactivate, Edit, Delete
- "Add Item" button present

## Step 9: Endorsements Page — PASS

- Navigated to `/app/content/endorsements`
- 4 endorsements with customer names, quotes, star ratings, sources:
  1. Jane D. — ★★★★★, Google, Featured
  2. Mike R. — ★★★★★, Yelp
  3. Sarah K. — ★★★★★, Google, Featured
  4. Tom B. — ★★★★☆, Direct
- Edit/Delete/Move buttons, "Add Endorsement" button

## Step 10: Mobile Layout (375×812) — PASS

- Resized to 375×812
- Hamburger menu button visible and clickable
- Sidebar hidden via CSS transform (-translate-x-full)
- Main content renders correctly at mobile width
- Dashboard content fully visible

## Step 11: ExUnit Tests — PASS

- Ran `mix test test/haul_web/live/app/` — 50 tests, 0 failures
- Full suite: `mix test` — 315 tests, 0 failures

## Step 12: Console Errors — PASS

- 0 errors at error level
- 0 warnings
- Only info-level LiveReloader messages (expected dev behavior)

## Summary

All 12 verification steps passed. One bug found and fixed (LoginLive tenant resolution). Full test suite green at 315 tests.
