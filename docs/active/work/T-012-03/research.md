# T-012-03 Research: Wildcard DNS

## Current State

### Fly.io Configuration (`fly.toml`)
- App name: `haul-page` (single shared app, not per-operator)
- Region: `iad`
- `PHX_HOST = "haul-page.fly.dev"` — currently set to the Fly default domain
- No `BASE_DOMAIN` env var set in fly.toml (only via runtime.exs env var)
- Health check at `/healthz`, scale-to-zero enabled

### Endpoint Configuration
- **config.exs**: Default `url: [host: "localhost"]`, base_domain defaults to `"localhost"`
- **runtime.exs**:
  - `BASE_DOMAIN` env var → `config :haul, :base_domain, base_domain`
  - Production: `host = System.get_env("PHX_HOST") || "example.com"`, sets `url: [host: host, port: 443, scheme: "https"]`
  - No `check_origin` config — Phoenix defaults to checking the configured host only

### TenantResolver Plug (`lib/haul_web/plugs/tenant_resolver.ex`)
- Resolution order: custom domain → subdomain → fallback
- Reads `Application.get_env(:haul, :base_domain, "localhost")` for subdomain extraction
- `extract_subdomain/2`: strips `.{base_domain}` suffix, returns prefix
- Bare base domain returns `nil` → triggers fallback
- Fallback uses operator config slug (`"junk-and-handy"`)
- Already fully functional — no code changes needed for subdomain routing

### Company Resource
- `slug` field: unique, indexed — used for subdomain matching
- `domain` field: unique, indexed — used for custom domain matching
- Both resolution paths tested in `test/haul_web/plugs/tenant_resolver_test.exs`

### Test Configuration
- `config :haul, :base_domain, "haulpage.test"` — tests use `.haulpage.test` suffix
- Tests verify: subdomain resolution, custom domain resolution, fallback, session storage

### Router
- TenantResolver in `:browser` pipeline — all browser routes get tenant context
- `/healthz` route is outside browser pipeline (no tenant resolution needed)

### Onboarding Runbook (`docs/knowledge/operator-onboarding.md`)
- Describes per-operator Fly apps (one app per operator)
- Step 7 covers custom domain via `fly certs add`
- No mention of wildcard DNS or shared platform domain
- This is the "old model" — T-012-03 introduces the shared SaaS model

## Key Observations

1. **TenantResolver is ready** — subdomain routing works, tested, no code changes needed
2. **Missing config**: `BASE_DOMAIN` not set in `fly.toml` env vars; needs to be `haulpage.com`
3. **PHX_HOST conflict**: Currently `haul-page.fly.dev`; for wildcard subdomains, this should probably remain as-is or be set to the bare base domain. PHX_HOST controls URL generation, not routing.
4. **check_origin**: Phoenix's default CORS check will reject WebSocket connections from `*.haulpage.com` subdomains. Must configure `check_origin` to allow wildcard pattern.
5. **Fly wildcard certs**: Fly supports wildcard certificates via `fly certs add "*.haulpage.com"`. The domain must be verified via DNS.
6. **DNS records needed**: A/AAAA records for `*.haulpage.com` and bare `haulpage.com` pointing to Fly app's shared IPv4/IPv6.
7. **Session cookie domain**: Default cookie config uses no explicit domain, which means cookies are host-scoped. For wildcard subdomains, each `slug.haulpage.com` gets its own cookies (correct behavior — tenants should not share sessions).

## Constraints

- Fly.io shared IPs: `fly ips list` shows allocated IPs for the app. Wildcard DNS A/AAAA records point to these.
- Fly TLS termination handles SSL; the app sees plain HTTP internally.
- The runbook currently describes per-operator Fly apps. T-012-03 adds a section for the SaaS wildcard model, not replacing the existing per-operator model.

## Files Relevant to Changes

| File | Change type | Reason |
|------|-------------|--------|
| `fly.toml` | Modify | Add `BASE_DOMAIN` env var |
| `config/runtime.exs` | Modify | Add `check_origin` config for wildcard subdomains |
| `docs/knowledge/operator-onboarding.md` | Modify | Add wildcard DNS setup section |
| `lib/haul_web/plugs/tenant_resolver.ex` | None | Already handles subdomains correctly |
| `test/haul_web/plugs/tenant_resolver_test.exs` | None | Already covers subdomain resolution |
