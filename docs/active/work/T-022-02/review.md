# T-022-02 Review: Proxy Link Helpers

## Summary

Added `HaulWeb.ProxyHelpers.tenant_path/2` — a helper that makes internal links proxy-aware. When viewing a tenant site under `/proxy/:slug/...`, links now stay within the proxy namespace instead of dropping to hostname-resolved routes.

## Changes

### Files created

| File | Purpose |
|------|---------|
| `lib/haul_web/proxy_helpers.ex` | `tenant_path/2` helper — prepends `/proxy/:slug` when proxy_slug is set |
| `test/haul_web/proxy_helpers_test.exs` | 7 unit tests for the helper |

### Files modified

| File | Change |
|------|--------|
| `lib/haul_web.ex` | Added `import HaulWeb.ProxyHelpers` to `:controller`, `:live_view`/`:html` (via `html_helpers`) |
| `lib/haul_web/live/scan_live.ex` | 2 links: `href="/book"` → `href={tenant_path(assigns, "/book")}` |
| `lib/haul_web/live/payment_live.ex` | 3 links: `href="/"` and `href={~p"/pay/..."}` → proxy-aware versions |
| `test/haul_web/plugs/proxy_routes_test.exs` | 2 new integration tests: proxy link verification + QR non-proxy assertion |

## Acceptance criteria verification

| Criterion | Status |
|-----------|--------|
| `tenant_path(assigns_or_conn, path)` with proxy_slug → `/proxy/:slug/path` | ✅ |
| `tenant_path` without proxy_slug → returns path unchanged | ✅ |
| All tenant-facing templates use helper for internal links | ✅ ScanLive (2), PaymentLive (3) |
| LiveView redirects use proxy-aware paths | ✅ (no LiveView redirects to tenant routes exist currently) |
| QR code encodes real URL, not proxy URL | ✅ Verified with test |
| Tests verify links within proxied pages point to `/proxy/:slug/...` | ✅ Integration test |

## Test results

- **Unit tests**: 7 passing (proxy_helpers_test.exs)
- **Integration tests**: 2 new in proxy_routes_test.exs, all passing
- **Full suite**: 780 tests, 0 failures (1 excluded)
- Test count increased from 746 to 780 (includes tests from T-022-01 and this ticket)

## Design decisions

- **Import via `haul_web.ex`** rather than per-file import — `tenant_path` is available everywhere without boilerplate
- **No changes to QR controller** — QR codes are for print and should encode real tenant URLs
- **No changes to ChatLive** — it only links to admin routes (`/app/*`), not tenant-facing routes
- **No changes to BookingLive or home template** — they have no internal tenant links
- **Helper works with both `Plug.Conn` and maps** — covers controller and LiveView contexts

## Open concerns

- **ChatLive admin links**: ChatLive links to `/app/signup` and `/app/content/site`. These are admin routes, not under proxy scope. If a proxy version of admin pages is ever needed, those links would need updating too. Not currently relevant.
- **Future tenant-facing links**: Any new tenant-facing link added to templates should use `tenant_path(assigns, path)`. The CLAUDE.md doesn't mention this convention yet — could be added if proxy support becomes a broader pattern.
- **Pre-existing format failures**: 4 files from other tickets have format issues (admin panel, timing formatter). Not introduced by this ticket.

## No critical issues requiring human attention.
