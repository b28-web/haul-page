# T-012-01 Structure: Tenant Resolver Plug

## Files Created

### `lib/haul_web/plugs/tenant_resolver.ex`
- Module: `HaulWeb.Plugs.TenantResolver`
- Implements `Plug` behaviour (`init/1`, `call/2`)
- `init/1` — accepts opts (none needed currently), returns them
- `call/2` — resolution pipeline:
  1. Extract host from `conn.host` (already stripped of port by Plug)
  2. `resolve_by_domain(host)` — `Ash.read_one(Company, filter: [domain: host])`
  3. `resolve_by_subdomain(host, base_domain)` — extract prefix, `Ash.read_one(Company, filter: [slug: prefix])`
  4. `fallback_tenant()` — load from operator config
  5. Assign `current_tenant` (Company struct or fallback map) and `tenant` (schema string)
- Private functions: `extract_subdomain/2`, `fallback_tenant/0`

### `test/haul_web/plugs/tenant_resolver_test.exs`
- Module: `HaulWeb.Plugs.TenantResolverTest`
- Uses `HaulWeb.ConnCase`
- Tests:
  - Subdomain resolution (slug.basedomain → correct company)
  - Custom domain resolution (custom domain → correct company)
  - Unknown host → fallback/demo tenant
  - Bare base domain → fallback/demo tenant
  - Port stripping (localhost:4000 → localhost)

## Files Modified

### `lib/haul/accounts/company.ex`
- Add `domain` attribute (nullable string, public)
- Add `identity :unique_domain, [:domain]`
- Update `:update_company` to accept `:domain`
- Add `:create_company` to accept `:domain`

### `lib/haul_web/router.ex`
- Add `plug HaulWeb.Plugs.TenantResolver` to `:browser` pipeline
- Add tenant-aware `:api_with_tenant` pipeline (for places API)
- Keep healthz and webhook scopes without tenant plug

### `config/config.exs`
- Add `config :haul, :base_domain, "localhost"`

### `config/runtime.exs`
- Add `BASE_DOMAIN` env var support

### Migration (new file)
- `priv/repo/migrations/TIMESTAMP_add_domain_to_companies.exs`
- Add `domain` column (nullable text) to companies table
- Add unique index on `domain` (where not null)

## Module Boundaries

- `TenantResolver` plug only does HTTP → Company lookup + assign
- Uses `Ash.read_one` for Company queries (public schema, no tenant needed)
- Uses `ProvisionTenant.tenant_schema/1` for schema name derivation
- Does NOT modify `ContentHelpers` — that's a gradual migration for downstream tickets

## Ordering

1. Migration (domain column)
2. Company resource changes (domain attribute + identity)
3. Config changes (base_domain)
4. TenantResolver plug
5. Router integration
6. Tests
