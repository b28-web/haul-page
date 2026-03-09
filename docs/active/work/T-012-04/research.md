# T-012-04 Research: Tenant Isolation Tests

## Multi-Tenancy Architecture

**Strategy:** Schema-per-tenant via AshPostgres `:context` strategy.
Each Company gets a Postgres schema named `tenant_{slug}` via `ProvisionTenant` change.

### Tenant-Scoped Resources (8 total)

All have identical multitenancy blocks at both resource and postgres levels:

| Resource | Domain | Table | Notes |
|----------|--------|-------|-------|
| `Haul.Accounts.User` | Accounts | users | Has policies + auth |
| `Haul.Accounts.Token` | Accounts | tokens | Auth tokens |
| `Haul.Operations.Job` | Operations | jobs | State machine, core business entity |
| `Haul.Content.SiteConfig` | Content | site_configs | Business config per tenant |
| `Haul.Content.Service` | Content | services | Service offerings |
| `Haul.Content.GalleryItem` | Content | gallery_items | Before/after photos |
| `Haul.Content.Endorsement` | Content | endorsements | Customer reviews |
| `Haul.Content.Page` | Content | pages | CMS pages |

### Non-Scoped Resources

- `Haul.Accounts.Company` — tenant root, public schema. No multitenancy config.

## Existing Test Coverage

### `test/haul/accounts/security_test.exs`
- Cross-tenant user query isolation (2 tests)
- Physical schema separation via direct SQL (1 test)
- Independent email uniqueness per tenant (1 test)
- Role-based policies: owner/crew read, update_profile, update_user (6 tests)
- Unauthenticated user rejection (1 test)

### What's NOT covered (gaps for T-012-04)
1. **Job isolation** — no cross-tenant job tests
2. **Content resource isolation** — SiteConfig, Service, GalleryItem, Endorsement not tested
3. **Job creation isolation** — create in A, verify absent in B
4. **Authentication boundary** — user in A can't sign in via tenant B
5. **Missing tenant context** — what happens when `tenant: nil` on scoped resources
6. **Defense in depth** — direct Ecto query with wrong schema prefix

## Test Helpers

- `Haul.DataCase` — SQL sandbox setup
- `HaulWeb.ConnCase` — `create_authenticated_context/1`, `cleanup_tenants/0`, `log_in_user/2`
- Pattern: `async: false` for tenant tests (schema DDL can't be sandboxed)
- Pattern: `on_exit` drops all `tenant_%` schemas

## Key API Patterns

```elixir
# Create with tenant
Resource |> Ash.Changeset.for_create(:action, attrs, tenant: tenant) |> Ash.create!()

# Read with tenant
Resource |> Ash.Query.for_read(:read, %{}, tenant: tenant) |> Ash.read!()

# Tenant schema derivation
ProvisionTenant.tenant_schema(company.slug)  # => "tenant_some-slug"
```

## Constraints

- Must use `async: false` — schema DDL operations conflict with async sandbox
- Must clean up schemas in `on_exit` — they persist outside sandbox
- Tests go in `test/haul/tenant_isolation_test.exs` (single consolidated module)
- Must run as part of `mix test`
