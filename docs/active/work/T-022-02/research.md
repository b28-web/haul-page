# T-022-02 Research: Proxy Link Helpers

## Proxy infrastructure (from T-022-01)

T-022-01 created a dev-only `/proxy/:slug` route scope that mirrors all tenant-facing routes. The infrastructure:

### ProxyTenantResolver plug (`lib/haul_web/plugs/proxy_tenant_resolver.ex`)
- Reads `:slug` from `conn.path_params`
- Looks up Company by slug
- Sets `conn.assigns.proxy_slug` = slug (string)
- Sets `conn.assigns.current_tenant`, `.tenant`, `.is_platform_host`
- Stores `proxy_slug` and `tenant_slug` in session

### ProxyTenantHook (`lib/haul_web/live/proxy_tenant_hook.ex`)
- LiveView on_mount hook for proxy routes
- Reads `session["proxy_slug"]` and `session["tenant_slug"]`
- Sets `socket.assigns.proxy_slug` on the socket

### TenantHook (normal flow, `lib/haul_web/live/tenant_hook.ex`)
- Does NOT set `proxy_slug` — assign is absent in normal tenant flow
- Only sets `current_tenant` and `tenant`

### Router (`lib/haul_web/router.ex`)
- Proxy routes at lines 142-155, guarded by `if Application.compile_env(:haul, :dev_routes)`
- Uses `:proxy_browser` pipeline with `ProxyTenantResolver` instead of `TenantResolver`
- Mounts same pages: `/`, `/scan`, `/book`, `/pay/:job_id`, `/start`, `/scan/qr`

## All internal links to tenant-facing routes

### ScanLive (`lib/haul_web/live/scan_live.ex`)
- Line 51: `href="/book"` — hardcoded "Book Online" button in hero
- Line 157: `href="/book"` — hardcoded "Book Online" button in footer CTA
- No other internal tenant links

### PaymentLive (`lib/haul_web/live/payment_live.ex`)
- Line 146: `href="/"` — "Go Home" link when job not found
- Line 175: `href={~p"/pay/#{@job.id}"}` — "Try Again" in error state
- Line 276: `href={~p"/pay/#{@job.id}"}` — "Try Again" in failed state

### ChatLive (`lib/haul_web/live/chat_live.ex`)
- Line 26: `redirect(socket, to: ~p"/app/signup")` — not a tenant route, admin redirect
- Lines 86, 236: `href={~p"/app/signup"}` — admin links, NOT tenant-facing
- Lines 191, 314: `href={~p"/app/content/site"}` — admin links, NOT tenant-facing
- No links to `/`, `/scan`, `/book` etc.

### BookingLive (`lib/haul_web/live/booking_live.ex`)
- No internal links to other tenant pages
- Phone tel: links only

### Home template (`lib/haul_web/controllers/page_html/home.html.heex`)
- No links to `/scan`, `/book`, `/start`
- Only phone/email links and a print button

### QR Controller (`lib/haul_web/controllers/qr_controller.ex`)
- Line 13: `url = HaulWeb.Endpoint.url() <> "/scan"` — hardcoded
- Per ticket AC: QR codes should encode the REAL tenant URL, not the proxy URL
- This is correct as-is — QR codes are for print, they should point to the real domain

### App.SignupLive (`lib/haul_web/live/app/signup_live.ex`)
- Line 130: `href={~p"/start"}` — cross-link from admin signup to tenant chat
- This is on an admin page, not under proxy scope, so it should NOT be proxy-rewritten

## Key observations

1. **Only 5 links need proxy-awareness**: 2 in ScanLive (`/book`), 3 in PaymentLive (`/`, `/pay/:id`)
2. **QR controller is correct as-is** — should NOT use proxy paths (QR codes are for print)
3. **ChatLive has no tenant-facing links** — only admin links to `/app/*`
4. **`proxy_slug` is only set in proxy flow** — normal TenantHook does not set it
5. **LiveViews get `proxy_slug` via socket assigns** from ProxyTenantHook; controllers get it from `conn.assigns`

## Constraints

- The helper must work for both conn (controllers) and socket assigns (LiveViews)
- Must be a no-op when `proxy_slug` is nil/absent (normal non-proxy flow)
- Must not break existing non-proxy routes
- Dev-only routes but the helper itself can exist in prod (it just returns paths unchanged)
