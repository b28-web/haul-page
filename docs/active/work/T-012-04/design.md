# T-012-04 Design: Tenant Isolation Tests

## Decision: Single Comprehensive Test Module

### Approach
One test module `test/haul/tenant_isolation_test.exs` with a shared setup that provisions two tenants and seeds distinct data in each. Test describes grouped by isolation domain.

### Why single module (vs per-resource test files)
- **Shared setup cost** — tenant provisioning (DDL) is expensive. One setup block seeds both tenants with all resource types, then all tests share that context.
- **Cohesion** — isolation is a cross-cutting concern. Having it in one place makes the security posture reviewable at a glance.
- **Matches acceptance criteria** — ticket explicitly says `test/haul/tenant_isolation_test.exs`.

### What exists vs what we add

The existing `SecurityTest` covers User isolation and role policies. We do NOT duplicate those tests. Instead, T-012-04 focuses on:

1. **Job isolation** (Operations domain)
2. **Content resource isolation** (all 5 Content resources)
3. **Cross-tenant authentication boundary**
4. **Missing tenant context rejection**
5. **Defense-in-depth direct SQL verification**

### Setup Design

```
setup:
  Company A ("Alpha Hauling") → tenant_alpha-hauling
    - User (owner)
    - Job (via create_from_online_booking)
    - SiteConfig
    - Service
    - GalleryItem
    - Endorsement

  Company B ("Beta Removal") → tenant_beta-removal
    - User (owner)
    - Job (different customer)
    - SiteConfig (different business name)
    - Service (different service)
```

### Test Groups

1. **`describe "job isolation"`** — 3 tests
   - Query jobs as A → only A's jobs
   - Query jobs as B → only B's jobs
   - Create job in A → not visible in B

2. **`describe "content isolation"`** — 4 tests
   - SiteConfig scoped per tenant
   - Services scoped per tenant
   - GalleryItems scoped per tenant
   - Endorsements scoped per tenant

3. **`describe "authentication boundary"`** — 1 test
   - User in A cannot sign_in_with_password in B's context

4. **`describe "missing tenant context"`** — 1 test
   - Ash operation without tenant on a scoped resource raises/errors

5. **`describe "defense in depth"`** — 1 test
   - Direct Ecto SQL to wrong schema returns empty

### Rejected Alternatives

- **Per-resource test files** — spreads security tests across many files, harder to audit.
- **Property-based testing** — overkill; we need deterministic assertions on specific resource types.
- **Using existing SecurityTest** — it's focused on User + role policies. Adding all resource types there would make it unwieldy and blur its purpose.
