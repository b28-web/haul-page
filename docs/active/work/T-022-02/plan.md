# T-022-02 Plan: Proxy Link Helpers

## Step 1: Create `HaulWeb.ProxyHelpers` module

Create `lib/haul_web/proxy_helpers.ex` with `tenant_path/2`.

Verify: module compiles (`mix compile`).

## Step 2: Import into view helpers

Add `import HaulWeb.ProxyHelpers` to the `:live_view` and `:html` using blocks in `lib/haul_web.ex`.

Verify: `mix compile` — no conflicts or warnings.

## Step 3: Write unit tests for `tenant_path/2`

Create `test/haul_web/proxy_helpers_test.exs`:
- `tenant_path(%{proxy_slug: "joe"}, "/book")` → `"/proxy/joe/book"`
- `tenant_path(%{proxy_slug: "joe"}, "/")` → `"/proxy/joe/"`
- `tenant_path(%{proxy_slug: "joe"}, "/pay/abc-123")` → `"/proxy/joe/pay/abc-123"`
- `tenant_path(%{}, "/book")` → `"/book"` (no proxy_slug key)
- `tenant_path(%{proxy_slug: nil}, "/book")` → `"/book"` (nil proxy_slug)

Verify: `mix test test/haul_web/proxy_helpers_test.exs` — all pass.

## Step 4: Update ScanLive links

Edit `lib/haul_web/live/scan_live.ex`:
- Line 51: `href="/book"` → `href={tenant_path(assigns, "/book")}`
- Line 157: `href="/book"` → `href={tenant_path(assigns, "/book")}`

Verify: `mix test test/haul_web/live/scan_live_test.exs` — existing tests pass (non-proxy flow unchanged).

## Step 5: Update PaymentLive links

Edit `lib/haul_web/live/payment_live.ex`:
- Line 146: `href="/"` → `href={tenant_path(assigns, "/")}`
- Line 175: `href={~p"/pay/#{@job.id}"}` → `href={tenant_path(assigns, ~p"/pay/#{@job.id}")}`
- Line 276: `href={~p"/pay/#{@job.id}"}` → `href={tenant_path(assigns, ~p"/pay/#{@job.id}")}`

Verify: `mix test test/haul_web/live/payment_live_test.exs` — existing tests pass.

## Step 6: Add proxy link integration tests

Extend `test/haul_web/plugs/proxy_routes_test.exs`:
- Mount ScanLive via `/proxy/slug/scan`, assert rendered HTML contains `href="/proxy/slug/book"` for "Book Online" links
- Mount PaymentLive via `/proxy/slug/pay/:job_id` (need to create a job), verify links

Verify: `mix test test/haul_web/plugs/proxy_routes_test.exs` — all pass.

## Step 7: Full suite

Run `mix test` to verify no regressions.

## Testing strategy

- **Unit tests**: `proxy_helpers_test.exs` — pure function, no DB
- **Integration tests**: `proxy_routes_test.exs` — verify links in rendered proxy pages
- **Regression**: existing scan_live, payment_live, booking_live tests confirm non-proxy flow unchanged
