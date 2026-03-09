# T-022-01 Research: ProxyTenantResolver Plug

## Existing Tenant Resolution Architecture

### TenantResolver Plug (`lib/haul_web/plugs/tenant_resolver.ex`)

Three-tier resolution from HTTP Host header:
1. Custom domain lookup: `Company |> Ash.Query.filter(domain == ^host) |> Ash.read_one()`
2. Subdomain extraction: `extract_subdomain(host, base_domain)` → `Company |> Ash.Query.filter(slug == ^subdomain) |> Ash.read_one()`
3. Fallback: operator config slug (default `"junk-and-handy"`)

Assigns set on conn:
- `current_tenant` → Company struct or nil
- `tenant` → `"tenant_#{slug}"` string (used for Ash multi-tenancy)
- `is_platform_host` → boolean (bare domain detection)

Session storage: `"tenant_slug"` and `"remote_ip"` stored in session.

### TenantHook (`lib/haul_web/live/tenant_hook.ex`)

LiveView on_mount hook. Reads `session["tenant_slug"]`, loads Company by slug, sets identical assigns on socket. Falls back to operator config if no slug in session.

### Router Structure (`lib/haul_web/router.ex`)

Browser pipeline includes: `:accepts`, `:fetch_session`, `:fetch_live_flash`, `:put_root_layout`, `:protect_from_forgery`, `:put_secure_browser_headers`, `TenantResolver`, `EnsureChatSession`.

Public scope `"/"` has:
- `get "/", PageController, :home`
- `get "/scan/qr", QRController, :generate`
- `live_session :tenant` with `TenantHook` on_mount: `/scan`, `/book`, `/pay/:job_id`, `/start`

Dev routes guarded by `if Application.compile_env(:haul, :dev_routes)` — currently only LiveDashboard at `/dev/dashboard`.

### Company Resource (`lib/haul/accounts/company.ex`)

Key fields: `slug` (unique string), `name`, `domain` (optional custom domain). Tenant schema name: `"tenant_#{slug}"` via `ProvisionTenant.tenant_schema/1`.

### EnsureChatSession (`lib/haul_web/plugs/ensure_chat_session.ex`)

Generates UUID `chat_session_id` in session if not present. Stateless, no tenant dependency. Must run in proxy pipeline too.

## Key Differences: Proxy vs Normal Resolution

| Aspect | TenantResolver | ProxyTenantResolver |
|--------|---------------|-------------------|
| Input | Host header | URL path param `:slug` |
| Failure mode | Fallback to operator config | Return 404 |
| Scope | All environments | Dev/test only |
| Extra assign | `is_platform_host` | `proxy_slug` |
| Session | Stores `tenant_slug` | Stores `tenant_slug` (same) |

## Template Link Patterns

Current links are hardcoded paths: `/book`, `/scan`, `/start`, `/pay/:job_id`. No proxy awareness. The ticket mentions a `tenant_path` helper but that could be a follow-up concern.

## Test Patterns

TenantResolver tests use `Plug.Test.init_test_session/2` and set `conn.host`. ProxyTenantResolver tests will use standard Phoenix `get/2` with `/proxy/:slug/...` paths.

## Files to Create

1. `lib/haul_web/plugs/proxy_tenant_resolver.ex` — new plug
2. `lib/haul_web/live/proxy_tenant_hook.ex` — new LiveView hook
3. `test/haul_web/plugs/proxy_tenant_resolver_test.exs` — plug tests
4. `test/haul_web/live/proxy_tenant_hook_test.exs` — hook tests

## Files to Modify

1. `lib/haul_web/router.ex` — add `:proxy_browser` pipeline + `/proxy/:slug` scope
