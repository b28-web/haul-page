# T-012-01 Research: Tenant Resolver Plug

## Current Multi-Tenancy Architecture

### Schema-per-tenant via AshPostgres `:context` strategy
- Every tenant-scoped resource declares `multitenancy do strategy :context end`
- Tenant-scoped resources: User, Token, Job, Service, SiteConfig, GalleryItem, Endorsement, Page
- Company is the tenant root — lives in the public schema, NOT tenant-scoped
- Tenant schema name: `"tenant_{slug}"` (derived by `ProvisionTenant.tenant_schema/1`)
- Schema created on Company creation via `ProvisionTenant` after_action hook

### Current Tenant Resolution (`ContentHelpers.resolve_tenant/0`)
- Reads `:operator` config from Application env → extracts `slug`
- Returns `"tenant_{slug}"` string
- Called directly in every LiveView mount and controller action
- Single-tenant: one operator per deployment, hardcoded in config

### Company Resource (`lib/haul/accounts/company.ex`)
- Fields: `id`, `slug` (required, unique), `name`, `timezone`, `subscription_plan`, `stripe_customer_id`
- Missing for this ticket: `domain` (nullable, unique for custom domain lookup)
- Identity: `:unique_slug` on `[:slug]`
- Actions: `:read` (defaults), `:create_company`, `:update_company`
- No `:read` action that filters by slug or domain — need to add or use default read + filter

### Router (`lib/haul_web/router.ex`)
- Pipelines: `:browser`, `:api`
- No tenant-aware plugs in any pipeline
- Routes: `/` (PageController), `/scan` (ScanLive), `/book` (BookingLive), `/pay/:job_id` (PaymentLive)
- API: `/api/places/autocomplete`, `/webhooks/stripe`
- Health check at `/healthz` — should NOT require tenant resolution

### Endpoint (`lib/haul_web/endpoint.ex`)
- Standard Phoenix plug stack → Router at the end
- LiveView socket at `/live` with session connect_info
- Tenant plug should go in router pipeline, not endpoint (healthz/webhooks don't need it)

### Config
- `config :haul, HaulWeb.Endpoint, url: [host: "localhost"]` in config.exs
- Production sets `PHX_HOST` env var for the base domain
- No `base_domain` config yet — needed for subdomain extraction

### Test Infrastructure
- `ConnCase`: builds conn, sets up sandbox, imports Phoenix.ConnTest
- `DataCase`: sandbox setup, Repo alias
- Tests pass `tenant:` kwarg to Ash operations manually
- No existing helpers for setting Host header or creating test companies

## Key Files

| File | Role |
|------|------|
| `lib/haul/accounts/company.ex` | Tenant root resource — needs `domain` attribute |
| `lib/haul_web/router.ex` | Router — needs tenant plug in browser pipeline |
| `lib/haul_web/content_helpers.ex` | Current hardcoded tenant resolution |
| `lib/haul/accounts/changes/provision_tenant.ex` | Schema name derivation (`tenant_schema/1`) |
| `lib/haul_web/endpoint.ex` | Plug stack — plug goes in router, not here |
| `config/config.exs` | Needs base_domain config |
| `config/runtime.exs` | Needs BASE_DOMAIN env var support |
| `test/support/conn_case.ex` | Test helper — may need tenant setup helper |

## Constraints & Assumptions

1. Company lookup must hit the public schema (Company is not tenant-scoped)
2. Subdomain extraction requires knowing the base domain (e.g., `haulpage.com`)
3. Health check and webhook routes must work WITHOUT tenant resolution
4. LiveView socket connections need tenant context too (but that's T-012-02)
5. The `slug` field already exists and is unique — subdomain lookup is straightforward
6. Custom domain lookup needs the new `domain` field + unique index
7. Demo/fallback tenant behavior: use operator config slug as default, or 404
