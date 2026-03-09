# T-012-02 Progress: LiveView Tenant Context

## Completed

### Step 1: TenantResolver session storage
- Added `maybe_put_session/3` to conditionally store `tenant_slug` in session
- Conditional because API pipeline doesn't fetch session
- Works for both company-resolved and fallback cases

### Step 2: TenantHook on_mount module
- Created `lib/haul_web/live/tenant_hook.ex`
- Reads `tenant_slug` from session, loads Company from DB
- Falls back to operator config slug if not found
- Always returns `{:cont, socket}` — never blocks rendering

### Step 3: Router live_session
- Wrapped `/scan`, `/book`, `/pay/:job_id` in `live_session :tenant`
- on_mount fires TenantHook for every LiveView mount

### Step 4-6: Updated all LiveViews
- BookingLive, ScanLive, PaymentLive all read `socket.assigns.tenant` instead of `ContentHelpers.resolve_tenant()`
- ContentHelpers still used for `load_site_config`, `load_gallery_items`, etc.

### Step 7-8: Tests
- Updated TenantResolver test to init session before calling plug
- Added 2 session storage tests to TenantResolver test
- Created `test/haul_web/live/tenant_hook_test.exs` with 5 tests:
  - LiveView receives tenant from TenantHook
  - LiveView with specific tenant company
  - Tenant re-verified on each mount
  - Different subdomains get different tenant contexts
  - Unknown subdomain falls back to default tenant

### Step 9: Full test suite
- 240 tests, 0 failures

## Deviation from plan
- Added `maybe_put_session/3` helper to handle API pipeline (no session) — not anticipated in plan
- Fixed pre-existing compilation error in `login_live.ex` (`Layouts.flash_group` → `HaulWeb.Layouts.flash_group`) to unblock test compilation
