# T-022-03 Research: Proxy Browser QA

## What exists

### Proxy Infrastructure (from T-022-01 and T-022-02)

**ProxyTenantResolver** (`lib/haul_web/plugs/proxy_tenant_resolver.ex`)
- Reads `:slug` from `conn.path_params`, looks up Company by slug
- Sets assigns: `current_tenant`, `tenant`, `proxy_slug`, `is_platform_host=false`
- Stores `tenant_slug` and `proxy_slug` in session
- Returns 404 for unknown slugs (no fallback)

**ProxyTenantHook** (`lib/haul_web/live/proxy_tenant_hook.ex`)
- LiveView `on_mount` hook, reads `proxy_slug` from session
- Loads Company, sets socket assigns: `current_tenant`, `tenant`, `proxy_slug`

**ProxyHelpers** (`lib/haul_web/proxy_helpers.ex`)
- `tenant_path(assigns_or_conn, path)` — prepends `/proxy/:slug` when `proxy_slug` present
- Used in ScanLive and PaymentLive for links

### Router Configuration (lines 133-158 of router.ex)

```elixir
scope "/proxy/:slug", HaulWeb do
  pipe_through :proxy_browser
  get "/", PageController, :home
  get "/scan/qr", QRController, :generate
  live_session :proxy_tenant, on_mount: [{HaulWeb.ProxyTenantHook, :resolve_tenant}] do
    live "/scan", ScanLive
    live "/book", BookingLive
    live "/pay/:job_id", PaymentLive
    live "/start", ChatLive
  end
end
```

Dev-only (`if Application.compile_env(:haul, :dev_routes)`).

### Existing Tests

**ProxyRoutesTest** (`test/haul_web/plugs/proxy_routes_test.exs`)
- Already tests: GET /, GET /scan/qr, LiveView /book mount, LiveView /scan mount
- Tests proxy-aware links on scan page (`href="/proxy/joes-hauling/book"`)
- Tests QR codes don't contain `/proxy/`

### What the QA test needs to verify beyond existing tests

1. **Landing page content** — business name, services rendering (not just 200 status)
2. **Navigation flow** — click Book Now → stays in proxy namespace
3. **Booking form interaction** — form renders, fields fillable
4. **Chat interface** — loads under proxy or redirects to fallback
5. **Cross-tenant switching** — different slug → different content
6. **LiveView events** — WebSocket works under proxy (form submit, etc.)

### QA Test Patterns

Existing QA tests (chat_qa_test.exs, provision_qa_test.exs) use:
- `use HaulWeb.ConnCase, async: false`
- `Phoenix.LiveViewTest` for LiveView interactions
- `live(conn, path)` → `{:ok, view, html}`
- `form()`, `element()`, `render_click()` for interactions
- Direct `send(view.pid, msg)` for simulating async events
- `Process.sleep()` for async settling
- Company creation + tenant provisioning in setup

### Key Files

| File | Role |
|------|------|
| `lib/haul_web/plugs/proxy_tenant_resolver.ex` | Plug: slug → tenant |
| `lib/haul_web/live/proxy_tenant_hook.ex` | LiveView hook: session → socket assigns |
| `lib/haul_web/proxy_helpers.ex` | `tenant_path/2` for proxy-aware links |
| `lib/haul_web/router.ex:133-158` | Proxy route definitions |
| `lib/haul_web/controllers/page_controller.ex` | Landing page (home action) |
| `lib/haul_web/live/scan_live.ex` | Scan page LiveView |
| `lib/haul_web/live/chat_live.ex` | Chat LiveView |
| `test/haul_web/plugs/proxy_routes_test.exs` | Existing route-level tests |
| `test/haul_web/live/provision_qa_test.exs` | Reference QA test pattern |

### Constraints

- Chat requires `Chat.configured?/0` — without LLM config, redirects to `/app/signup`
- Tenant provisioning needed for content to exist (SiteConfig, Services, etc.)
- Dev routes guard means tests must run in dev/test config where `dev_routes` is true
- Rate limiter ETS table needs clearing between tests
