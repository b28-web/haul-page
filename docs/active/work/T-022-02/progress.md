# T-022-02 Progress: Proxy Link Helpers

## Completed

- [x] Step 1: Created `lib/haul_web/proxy_helpers.ex` with `tenant_path/2`
- [x] Step 2: Added `import HaulWeb.ProxyHelpers` to `:html`, `:live_view`, and `:controller` blocks in `haul_web.ex`
- [x] Step 3: Unit tests for `tenant_path/2` — 7 tests passing
- [x] Step 4: Updated ScanLive — 2 `href="/book"` → `href={tenant_path(assigns, "/book")}`
- [x] Step 5: Updated PaymentLive — 3 links updated (1x `/`, 2x `/pay/:id`)
- [x] Step 6: Added proxy link integration tests to `proxy_routes_test.exs` — scan page proxy links and QR code non-proxy assertion
- [x] Step 7: Full suite — 780 tests, 0 failures (1 excluded)

## Remaining

None — all steps complete.

## Deviations

None — plan followed exactly.
