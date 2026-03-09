# T-012-05 Research: Browser QA for Tenant Routing

## Scope

Playwright MCP verification of multi-tenant routing. Confirm subdomain-based and custom-domain-based tenant resolution serves correct operator content.

## Tenant Resolution Flow

### TenantResolver Plug (`lib/haul_web/plugs/tenant_resolver.ex`)

Three-tier resolution from Host header:
1. **Custom domain** — `Company |> filter(domain == ^host)` (checked first)
2. **Subdomain** — extract prefix from host (e.g., `bobs.haulpage.test` → `bobs`), look up by `slug`
3. **Fallback** — uses `Application.get_env(:haul, :operator)[:slug]` (default operator)

Assigns to conn:
- `conn.assigns.current_tenant` — Company struct
- `conn.assigns.tenant` — Postgres schema string (`"tenant_slug"`)
- `session["tenant_slug"]` — for LiveView reconnects

### TenantHook (`lib/haul_web/live/tenant_hook.ex`)

LiveView `on_mount` hook reads `session["tenant_slug"]`, loads Company fresh from DB, assigns to socket. Falls back to operator config if slug not found.

### Base Domain Config

- `config/test.exs`: `config :haul, :base_domain, "haulpage.test"`
- `config/config.exs`: `config :haul, :base_domain, "localhost"`
- `config/runtime.exs`: reads `BASE_DOMAIN` env var

### Routes Under Test

All browser pipeline routes have TenantResolver plug:
- `GET /` — PageController (server-rendered landing page)
- `GET /scan` — ScanLive (LiveView)
- `GET /book` — BookingLive (LiveView)
- `GET /pay/:job_id` — PaymentLive (LiveView)

### Company Resource

Key fields: `slug` (unique), `domain` (unique, optional), `name`.
`ProvisionTenant.tenant_schema(slug)` returns `"tenant_slug"`.

### Content Seeding

`Haul.Content.Seeder.seed!(tenant)` populates SiteConfig, Services, GalleryItems, Endorsements, Pages from YAML. Operator-specific content from `priv/content/operators/{slug}/`.

### Existing Test Infrastructure

- `test/haul_web/plugs/tenant_resolver_test.exs` — unit tests for plug resolution
- `test/haul_web/live/tenant_hook_test.exs` — LiveView hook tests
- `test/haul/tenant_isolation_test.exs` — Ash-level isolation tests
- `test/haul_web/smoke_test.exs` — route smoke tests (single tenant)

### Playwright MCP

Configured in `.mcp.json`. Previous browser QA tickets (T-002-04, T-003-04, T-005-04, T-006-05, T-009-03) used Playwright MCP tools to navigate, snapshot, type, click in headless Chrome against `localhost:4000`.

### Challenge: Host Header in Browser

Playwright navigates to URLs. To test subdomain routing, we need:
- Tenant companies provisioned with known slugs
- Content seeded for each tenant
- Navigate to different hostnames (subdomains) that resolve to localhost:4000

Options for hostname resolution:
1. Use `localhost` with port — fallback tenant only
2. Playwright `browser_navigate` with different URLs — needs DNS/hosts entries for subdomains
3. Test via the Playwright `browser_evaluate` to set Host headers (not possible in browser context)
4. Test via server-side by confirming plug/hook tests pass, then do browser QA on the fallback tenant content differentiation

### Existing Tenant Data

The `priv/content/operators/` directory may contain operator-specific content. Default content in `priv/content/` serves the fallback operator.

## Key Constraints

1. Browser cannot set arbitrary Host headers — subdomains must resolve via DNS or /etc/hosts
2. Dev server must be running on port 4000
3. Playwright MCP uses headless Chrome — standard browser networking applies
4. Test config uses `haulpage.test` as base domain, dev uses `localhost`
5. Content must be seeded for tenants before navigation

## Files Involved

- `lib/haul_web/plugs/tenant_resolver.ex` — Host-to-tenant resolution
- `lib/haul_web/live/tenant_hook.ex` — LiveView tenant context
- `lib/haul_web/router.ex` — Route definitions with tenant pipeline
- `lib/haul/accounts/company.ex` — Company resource
- `lib/haul/content/seeder.ex` — Content seeding
- `config/config.exs` — base_domain config
- `priv/content/` — Default operator content
- `priv/content/operators/` — Per-operator content
