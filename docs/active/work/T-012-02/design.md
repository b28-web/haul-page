# T-012-02 Design: LiveView Tenant Context

## Problem
LiveViews resolve tenant from global config (`Application.get_env`), ignoring the per-request tenant resolved by TenantResolver plug. All tenants see the same data.

## Options Considered

### Option A: Store tenant in session, read in on_mount
1. TenantResolver plug writes `tenant` and `current_tenant` (or just slug) to `conn` session
2. A new `on_mount` hook reads tenant from session, re-resolves Company from DB
3. All LiveViews get tenant from socket assigns instead of ContentHelpers

**Pros:** Standard Phoenix pattern. Tenant verified on every mount (including reconnect). Session data travels with the WebSocket. Clean separation — plug handles HTTP, hook handles WS.
**Cons:** Extra DB query on each mount to re-verify company. Requires adding `put_session` to TenantResolver plug.

### Option B: Pass tenant via connect_params (JavaScript)
Client-side JS sends tenant info via `liveSocket` connect params.
**Rejected:** Client can forge any tenant — violates "re-verified on reconnect" requirement. Security hole.

### Option C: Resolve tenant from URI in on_mount
Read `get_connect_info(:uri)` or `get_connect_info(:peer_data)` in mount to extract host and re-run resolution.
**Rejected:** `get_connect_info` only available during connected mount, not dead render. Would need fallback for dead render. Also couples LiveView to HTTP-level host resolution.

### Option D: Use live_session with on_mount + session hook
Wrap LiveView routes in `live_session` with `:on_mount` and a session function that copies conn assigns to session.
**Pros:** Clean, declarative. The session function runs during dead render and passes data to WS mount. Standard Phoenix 1.7+ pattern.
**Cons:** Slightly more setup than Option A.

## Decision: Option A + D hybrid

Use both mechanisms for correctness:

1. **TenantResolver plug** writes `tenant` (string) and `tenant_slug` (string) to the session via `put_session`. This ensures session data persists to WebSocket.

2. **New `on_mount` hook** (`TenantHook`) reads `tenant` and `tenant_slug` from session. Re-verifies by loading Company from DB by slug. Sets `socket.assigns.tenant` and `socket.assigns.current_tenant`.

3. **`live_session` block** in router wraps all tenant-aware LiveView routes with `on_mount: [{HaulWeb.TenantHook, :resolve_tenant}]`.

4. **LiveViews updated** to use `socket.assigns.tenant` instead of `ContentHelpers.resolve_tenant()`.

### Why re-verify from DB on every mount?
- Acceptance criteria: "Tenant is re-verified on socket reconnect"
- Company could be deleted/deactivated between mounts
- Slug-to-schema mapping must be current
- One DB query per mount is negligible

### Why not store Company struct in session?
- Session is serialized to cookie — structs are fragile across deploys
- Only store the slug (small string), re-load Company struct from DB

### Session keys
- `"tenant_slug"` — the company slug (e.g., `"joes-hauling"`)
- The `tenant` schema string is derived from slug: `"tenant_#{slug}"`
- `current_tenant` (Company struct) is loaded fresh from DB

### Security: tenant switching prevention
- Session is signed — client can't modify slug
- on_mount re-verifies slug against DB on every mount
- If company not found, LiveView gets fallback tenant (same as plug behavior)
- No mechanism for client to inject a different tenant mid-session

## ContentHelpers changes
- `resolve_tenant/0` (no-arg, global config) stays for backward compat with non-LiveView controllers
- LiveViews stop calling it — they use socket assigns instead
