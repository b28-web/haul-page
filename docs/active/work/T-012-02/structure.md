# T-012-02 Structure: LiveView Tenant Context

## Files Modified

### 1. `lib/haul_web/plugs/tenant_resolver.ex` (modify)
- Add `put_session(conn, "tenant_slug", slug)` after tenant resolution
- For fallback case (no company), store the fallback slug in session too

### 2. `lib/haul_web/live/tenant_hook.ex` (create)
- New module: `HaulWeb.TenantHook`
- `on_mount(:resolve_tenant, _params, session, socket)` function
- Reads `session["tenant_slug"]`, loads Company from DB by slug
- Sets `socket.assigns.current_tenant` (Company or nil) and `socket.assigns.tenant` (schema string)
- Fallback behavior mirrors TenantResolver plug (uses operator config slug)

### 3. `lib/haul_web/router.ex` (modify)
- Wrap existing LiveView routes in `live_session :tenant, on_mount: [{HaulWeb.TenantHook, :resolve_tenant}]`
- Session function to pass tenant_slug from conn to LiveView session

### 4. `lib/haul_web/live/booking_live.ex` (modify)
- Remove `ContentHelpers.resolve_tenant()` call
- Use `socket.assigns.tenant` instead
- Load site_config using `socket.assigns.tenant`

### 5. `lib/haul_web/live/scan_live.ex` (modify)
- Same changes as BookingLive

### 6. `lib/haul_web/live/payment_live.ex` (modify)
- Same changes as BookingLive
- Already stores tenant in assigns for Ash operations — just change the source

### 7. `test/haul_web/live/tenant_hook_test.exs` (create)
- Test on_mount reads tenant from session
- Test tenant re-verification on mount
- Test fallback when company not found
- Test that socket assigns are set correctly

### 8. `test/haul_web/live/booking_live_test.exs` (modify or create)
- Test LiveView mount with tenant context
- Verify tenant isolation — tenant A data not visible to tenant B

## Module Boundaries

```
TenantResolver (Plug)          TenantHook (on_mount)
  ↓                              ↓
conn.assigns.tenant            socket.assigns.tenant
conn.assigns.current_tenant    socket.assigns.current_tenant
session["tenant_slug"]         reads session["tenant_slug"]
```

Both resolve to the same tenant string format. TenantHook re-verifies by loading Company from DB.

## Public Interfaces

### HaulWeb.TenantHook
```elixir
def on_mount(:resolve_tenant, params, session, socket) :: {:cont, socket} | {:halt, socket}
```
Always continues (`:cont`) — tenant resolution never blocks page load. Falls back to default tenant if company not found.

## Ordering
1. TenantResolver plug changes (session storage) — must come first
2. TenantHook module creation
3. Router changes (live_session wrapper)
4. LiveView updates (all three)
5. Tests
