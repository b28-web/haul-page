# T-022-01 Design: ProxyTenantResolver Plug

## Decision: Separate Pipeline + Shared Company Lookup

### Approach

Create a `:proxy_browser` pipeline that duplicates `:browser` but replaces `TenantResolver` with `ProxyTenantResolver`. This avoids modifying the existing pipeline and keeps proxy logic fully isolated behind `dev_routes`.

### Alternatives Considered

**A) Inline plug in scope** — Add `plug ProxyTenantResolver` inside the scope block instead of a pipeline. Rejected: Phoenix scopes don't support inline plug calls outside pipelines for controller routes.

**B) Conditional plug in existing pipeline** — Make TenantResolver check for proxy path params and switch behavior. Rejected: Contaminates production code with dev-only logic, violates "not compiled in prod" requirement.

**C) Separate pipeline (chosen)** — Dedicated `:proxy_browser` pipeline with ProxyTenantResolver instead of TenantResolver. Clean separation, easy to guard behind `dev_routes`, no impact on existing routes.

### ProxyTenantResolver Design

```elixir
# Reads :slug from conn.path_params (set by Phoenix router)
# Looks up Company by slug (same query as TenantResolver)
# Sets: current_tenant, tenant, proxy_slug
# Returns 404 (not fallback) on unknown slug
```

Key decisions:
- **Strict 404**: Unlike TenantResolver's fallback behavior, proxy returns 404 for unknown slugs. This catches developer errors immediately.
- **proxy_slug assign**: Set to the slug string so templates/LiveViews can detect proxy mode and generate correct paths.
- **Same session pattern**: Store `tenant_slug` in session so ProxyTenantHook can read it (same as TenantHook pattern).

### ProxyTenantHook Design

Mirrors TenantHook but also sets `proxy_slug` on socket from the session. The slug is stored in session by ProxyTenantResolver, and the hook reads it back on LiveView mount.

```elixir
# on_mount(:resolve_tenant, params, session, socket)
# Reads session["tenant_slug"] and session["proxy_slug"]
# Loads Company by slug
# Sets: current_tenant, tenant, proxy_slug on socket
```

### Router Design

```elixir
if Application.compile_env(:haul, :dev_routes) do
  pipeline :proxy_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HaulWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug HaulWeb.Plugs.ProxyTenantResolver
    plug HaulWeb.Plugs.EnsureChatSession
  end

  scope "/proxy/:slug", HaulWeb do
    pipe_through :proxy_browser
    get "/", PageController, :home
    get "/scan/qr", QRController, :generate
    live_session :proxy_tenant,
      on_mount: [{HaulWeb.ProxyTenantHook, :resolve_tenant}] do
      live "/scan", ScanLive
      live "/book", BookingLive
      live "/pay/:job_id", PaymentLive
      live "/start", ChatLive
    end
  end
end
```

### Template Links

For this ticket, links within proxy pages will be relative paths (`/book`) which won't work correctly under `/proxy/:slug/`. The ticket mentions a `tenant_path` helper as a "consider" item. For this implementation:
- Set `proxy_slug` assign so it's available in templates
- Actual path rewriting is a follow-up concern (not in acceptance criteria as a hard requirement)

### Impact on Existing Routes

Zero. The proxy pipeline and scope are inside a `dev_routes` guard. No existing code is modified. Both pipelines share the same controllers and LiveViews — they just resolve tenants differently.

### is_platform_host Handling

ProxyTenantResolver always sets `is_platform_host: false` since proxy mode always targets a specific tenant. This ensures PageController renders the operator home, not the marketing page.
