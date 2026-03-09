# T-022-02 Structure: Proxy Link Helpers

## Files created

### 1. `lib/haul_web/proxy_helpers.ex`
New module `HaulWeb.ProxyHelpers`.

Public API:
```
tenant_path(assigns_or_conn, path) :: String.t()
```

- Accepts map (socket assigns), `%Plug.Conn{}`, or anything with `proxy_slug` field
- Returns `"/proxy/#{proxy_slug}#{path}"` when proxy_slug is set
- Returns `path` unchanged when proxy_slug is nil or absent
- Uses `Map.get/3` with default nil to handle missing key gracefully (no KeyError in normal flow where proxy_slug is never assigned)

### 2. `test/haul_web/proxy_helpers_test.exs`
Unit tests for `tenant_path/2`:
- With proxy_slug set → prepends proxy prefix
- Without proxy_slug → returns path unchanged
- With nil proxy_slug → returns path unchanged
- With ~p sigil path → prepends correctly
- With "/" path → returns "/proxy/slug/" or "/"

## Files modified

### 3. `lib/haul_web.ex`
Add `import HaulWeb.ProxyHelpers` to the `:live_view` and `:html` `using` blocks so `tenant_path/2` is available in all templates and LiveViews.

### 4. `lib/haul_web/live/scan_live.ex`
- Line 51: `href="/book"` → `href={tenant_path(assigns, "/book")}`
- Line 157: `href="/book"` → `href={tenant_path(assigns, "/book")}`

### 5. `lib/haul_web/live/payment_live.ex`
- Line 146: `href="/"` → `href={tenant_path(assigns, "/")}`
- Line 175: `href={~p"/pay/#{@job.id}"}` → `href={tenant_path(assigns, ~p"/pay/#{@job.id}")}`
- Line 276: `href={~p"/pay/#{@job.id}"}` → `href={tenant_path(assigns, ~p"/pay/#{@job.id}")}`

### 6. `test/haul_web/plugs/proxy_routes_test.exs`
Add test that verifies links within proxied pages point to `/proxy/:slug/...` paths:
- Mount ScanLive via proxy route, assert "Book Online" link href contains `/proxy/slug/book`
- Mount PaymentLive via proxy route (with a job), verify "Go Home" link points to `/proxy/slug/`

## Files NOT modified

- `lib/haul_web/controllers/qr_controller.ex` — QR codes encode real URLs, not proxy URLs (per AC)
- `lib/haul_web/live/chat_live.ex` — only has admin links, not tenant-facing
- `lib/haul_web/live/booking_live.ex` — no internal tenant links
- `lib/haul_web/controllers/page_html/home.html.heex` — no internal tenant links

## Ordering

1. Create `ProxyHelpers` module
2. Add import to `haul_web.ex`
3. Update ScanLive and PaymentLive links
4. Write unit tests for helper
5. Add integration test for proxy link correctness
