# T-012-05 Design: Browser QA for Tenant Routing

## Decision

Use Playwright MCP to verify tenant routing by navigating to `localhost:4000` (default/fallback tenant) and verifying content renders correctly. For multi-tenant differentiation, verify via the existing ExUnit tests (plug tests, hook tests, isolation tests) which already cover subdomain and custom domain resolution. The browser QA focuses on what Playwright can actually verify: the end-to-end flow of a tenant-resolved page rendering correct content.

## Options Considered

### Option A: /etc/hosts entries for subdomains (rejected)

Add entries like `127.0.0.1 alpha.localhost` and navigate Playwright to subdomain URLs.

**Pros:** Tests real subdomain resolution end-to-end in browser
**Cons:** Requires modifying system `/etc/hosts` (risky, requires sudo, not portable). `*.localhost` doesn't always resolve correctly across OSes. Dev server uses `localhost` as base_domain — subdomain extraction from `alpha.localhost` against base domain `localhost` would actually work, but DNS resolution of `alpha.localhost` is unreliable.

**Rejected:** System modification is fragile and not reproducible.

### Option B: Navigate to localhost, verify default tenant content (chosen)

Navigate to `localhost:4000` — TenantResolver falls back to operator config slug. Verify that:
1. The fallback tenant's content renders (business name, services, etc.)
2. LiveViews connect and load with tenant context
3. Pages respond correctly at `/`, `/scan`, `/book`
4. Mobile viewport works
5. No console errors

Additionally, run the existing ExUnit test suite to confirm multi-tenant routing logic at the code level — the plug tests, hook tests, and isolation tests already cover subdomain/custom-domain/cross-tenant scenarios comprehensively.

**Pros:** Works reliably with no system changes. Validates the full browser rendering pipeline. Combined with existing tests, provides complete coverage.
**Cons:** Doesn't exercise subdomain URL in browser. But the subdomain logic is thoroughly unit-tested.

**Chosen:** Practical approach that verifies what matters (content renders for resolved tenant) without fragile system modifications.

### Option C: Spin up test server with custom port and use lvh.me (rejected)

Use `lvh.me` (which resolves `*.lvh.me` to 127.0.0.1) as a way to test subdomains.

**Pros:** Real subdomain resolution without /etc/hosts changes
**Cons:** Requires internet connectivity for DNS. Need to reconfigure base_domain to `lvh.me`. Dev server config changes. Adds external dependency.

**Rejected:** External DNS dependency is fragile for QA.

## Test Plan

### Playwright MCP Steps

1. **Health check** — Navigate to `localhost:4000/healthz`, verify 200
2. **Landing page** — Navigate to `localhost:4000/`, verify page renders with operator's business name
3. **Scan page** — Navigate to `localhost:4000/scan`, verify LiveView mounts with tenant content
4. **Booking page** — Navigate to `localhost:4000/book`, verify LiveView mounts with tenant context
5. **Mobile viewport** — Resize to 375x812, navigate to `/`, verify responsive rendering
6. **Console check** — Verify no JS errors across all navigation

### ExUnit Verification

Run `mix test` to confirm all existing tenant tests pass:
- `test/haul_web/plugs/tenant_resolver_test.exs` (subdomain + custom domain resolution)
- `test/haul_web/live/tenant_hook_test.exs` (LiveView tenant context)
- `test/haul/tenant_isolation_test.exs` (cross-tenant data isolation)

### Acceptance Criteria Mapping

- "All tenant routing scenarios verified via Playwright MCP snapshots" → Steps 1-5 + ExUnit tests
- "No cross-tenant data leakage observed" → Isolation tests in ExUnit suite
- "Failures documented with snapshot output" → Any failures captured in progress.md
