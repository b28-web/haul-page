# T-012-02 Plan: LiveView Tenant Context

## Step 1: Update TenantResolver to store slug in session
- Modify `call/2` to `put_session(conn, "tenant_slug", slug)` after resolution
- For company match: store `company.slug`
- For fallback: store the fallback slug
- Requires `fetch_session` to have run first (it does — `:browser` pipeline calls it)
- **Verify:** Existing TenantResolver tests still pass

## Step 2: Create TenantHook on_mount module
- Create `lib/haul_web/live/tenant_hook.ex`
- `on_mount(:resolve_tenant, _params, session, socket)`
- Read `session["tenant_slug"]`, look up Company by slug
- If found: assign `current_tenant` (struct) and `tenant` (schema string)
- If not found: assign `current_tenant: nil` and `tenant` from fallback slug
- Always return `{:cont, socket}`
- **Verify:** Module compiles

## Step 3: Add live_session to router
- Wrap LiveView routes in `live_session :tenant` block
- Add `on_mount: [{HaulWeb.TenantHook, :resolve_tenant}]`
- Add session function: `session: {__MODULE__, :copy_tenant_to_session, []}` to pass conn assigns to LV session
  - Actually, since we're using put_session in the plug, the session already has `tenant_slug` — no session function needed
- **Verify:** `mix compile` succeeds

## Step 4: Update BookingLive
- Remove `ContentHelpers.resolve_tenant()` call from mount
- Use `socket.assigns.tenant` (set by TenantHook)
- Load site_config with `ContentHelpers.load_site_config(socket.assigns.tenant)`
- **Verify:** `mix compile`

## Step 5: Update ScanLive
- Same pattern as BookingLive
- **Verify:** `mix compile`

## Step 6: Update PaymentLive
- Same pattern as BookingLive
- PaymentLive already stores tenant in assigns for Ash operations — just change source
- **Verify:** `mix compile`

## Step 7: Write TenantHook tests
- Test: mount with valid tenant slug in session → assigns set correctly
- Test: mount with unknown slug → falls back to default tenant
- Test: mount with no slug in session → falls back to default tenant
- Test: company loaded fresh from DB (re-verification)
- **Verify:** Tests pass

## Step 8: Write tenant isolation LiveView test
- Create a company, provision its tenant schema
- Mount BookingLive with that company's slug in session
- Verify tenant assign matches expected schema
- **Verify:** Tests pass

## Step 9: Run full test suite
- `mix test` — all 201+ tests pass
- No regressions from session/router changes

## Testing Strategy
- **Unit tests:** TenantHook on_mount with mocked session data
- **Integration tests:** LiveView mount through router with tenant context
- **Isolation test:** Two tenants can't cross-contaminate
- Existing TenantResolver plug tests cover HTTP layer — no changes needed there beyond verifying session storage
