# T-012-05 Plan: Browser QA for Tenant Routing

## Prerequisites

- Dev server running on `localhost:4000`
- Default operator tenant provisioned + content seeded
- Playwright MCP connected

## Step 1: Verify Dev Server Health

1. `browser_navigate` to `http://localhost:4000/healthz`
2. `browser_snapshot` — verify "ok" response
3. **Pass:** Page loads without error

## Step 2: Landing Page — Tenant Content Renders

1. `browser_navigate` to `http://localhost:4000/`
2. `browser_snapshot` — capture full page
3. **Verify:**
   - Page renders with operator's business name
   - Services section visible
   - Phone number / CTA present
   - Dark theme applied
4. **Pass:** Tenant-specific content visible on landing page

## Step 3: Scan Page — LiveView with Tenant Context

1. `browser_navigate` to `http://localhost:4000/scan`
2. `browser_snapshot` — capture after LiveView mount
3. **Verify:**
   - LiveView connects (no "LiveView disconnected" error)
   - Gallery content rendered from tenant's seeded data
   - CTA elements present
4. **Pass:** LiveView mounts with tenant content

## Step 4: Booking Page — LiveView with Tenant Context

1. `browser_navigate` to `http://localhost:4000/book`
2. `browser_snapshot` — capture after mount
3. **Verify:**
   - Booking form renders (name, phone, address, description fields)
   - LiveView connected
   - Tenant context doesn't cause errors
4. **Pass:** Booking form renders in tenant context

## Step 5: Mobile Viewport

1. `browser_resize` to 375x812 (iPhone viewport)
2. `browser_navigate` to `http://localhost:4000/`
3. `browser_snapshot` — capture mobile layout
4. **Verify:**
   - Page renders without horizontal overflow
   - Content still visible and readable
   - Navigation adapts to mobile
5. **Pass:** Responsive layout works under tenant context

## Step 6: Console Error Check

1. `browser_console_messages` — collect all messages
2. **Verify:** No errors or uncaught exceptions
3. **Pass:** Clean console

## Step 7: ExUnit Test Suite

1. Run `mix test test/haul_web/plugs/tenant_resolver_test.exs test/haul_web/live/tenant_hook_test.exs test/haul/tenant_isolation_test.exs`
2. **Verify:** All tests pass
3. **Pass:** Subdomain resolution, custom domain resolution, cross-tenant isolation all verified at code level

## Bug Handling

- If dev server not running → start it, re-run steps
- If tenant not provisioned → seed content first, retry
- If LiveView disconnects → check server logs, document error
- Trivial issues fixed inline; complex issues documented for follow-up
