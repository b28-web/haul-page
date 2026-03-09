# T-012-02 Research: LiveView Tenant Context

## Current State

### Tenant Resolution (HTTP layer)
- `HaulWeb.Plugs.TenantResolver` resolves tenant from Host header in the `:browser` pipeline
- Resolution order: custom domain → subdomain → fallback (operator config slug)
- Sets `conn.assigns.current_tenant` (Company struct or nil) and `conn.assigns.tenant` (Postgres schema string like `"tenant_joes-hauling"`)
- Runs on every HTTP request in the `:browser` pipeline (router.ex:11)

### LiveView Tenant Resolution (current pattern — broken)
All three LiveViews use `ContentHelpers.resolve_tenant()` in mount:
- `BookingLive.mount/3` — line 13: `tenant = ContentHelpers.resolve_tenant()`
- `ScanLive.mount/3` — line 8: same
- `PaymentLive.mount/3` — line 9: same

`ContentHelpers.resolve_tenant/0` reads `Application.get_env(:haul, :operator)[:slug]` — this is the **global operator config**, not the per-request tenant. This means:
- **All LiveViews currently use the same hardcoded tenant regardless of which subdomain the user visits**
- The tenant resolved by TenantResolver plug is never passed to LiveViews
- On WebSocket reconnect, tenant is re-derived from global config (same broken behavior)

### Session Configuration
- Endpoint (`endpoint.ex`): cookie session with key `"_haul_key"`, signing_salt `"8v5yFT1O"`
- WebSocket connect_info includes session: `socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]`
- Session data IS available in LiveView `mount/3` second argument

### Existing on_mount Hooks
- `HaulWeb.AuthHooks.on_mount(:require_auth, ...)` — reads `session["user_token"]` and `session["tenant"]` to authenticate users
- Already expects tenant to be in the session — but nobody puts it there yet
- Not used by any `live_session` block currently (no `live_session` blocks exist in router)

### Router Structure
```elixir
scope "/", HaulWeb do
  pipe_through :browser   # includes TenantResolver
  live "/scan", ScanLive
  live "/book", BookingLive
  live "/pay/:job_id", PaymentLive
end
```
No `live_session` wrappers exist. All LiveViews are bare `live` routes.

### Key Files
| File | Role |
|------|------|
| `lib/haul_web/plugs/tenant_resolver.ex` | HTTP tenant resolution |
| `lib/haul_web/live/auth_hooks.ex` | Existing on_mount hook (auth) |
| `lib/haul_web/content_helpers.ex` | Broken global tenant resolution |
| `lib/haul_web/live/booking_live.ex` | LiveView — uses ContentHelpers |
| `lib/haul_web/live/scan_live.ex` | LiveView — uses ContentHelpers |
| `lib/haul_web/live/payment_live.ex` | LiveView — uses ContentHelpers |
| `lib/haul_web/router.ex` | Router — no live_session blocks |
| `lib/haul_web/endpoint.ex` | Session config, WS connect_info |
| `test/support/conn_case.ex` | Test case — no tenant setup |

### Phoenix LiveView Session Flow
1. Initial HTTP request: Plug pipeline runs → TenantResolver sets `conn.assigns`
2. LiveView mount (dead render): `mount/3` receives `session` map from cookie
3. WebSocket upgrade: client sends session token, server verifies and passes to `mount/3`
4. Reconnect: same as #3 — `mount/3` is called again with session from cookie

**Critical insight:** `conn.assigns` are NOT automatically available in LiveView mount. The session cookie IS. So the plug must write tenant to session for LiveView to read it.

### Tenant String Format
- `ProvisionTenant.tenant_schema(slug)` returns `"tenant_#{slug}"`
- Company.slug is the source of truth
- Company struct has: id, slug, name, timezone, subscription_plan, domain

## Constraints
- Multi-tenancy uses AshPostgres `:context` strategy (schema-per-tenant)
- Tenant must be a string (schema name), not a struct
- Both `tenant` (string) and `current_tenant` (Company struct) should be available
- Session cookie is signed but not encrypted — don't store sensitive data
- Must work on reconnect without trusting stale data
