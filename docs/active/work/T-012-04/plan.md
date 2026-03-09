# T-012-04 Plan: Tenant Isolation Tests

## Steps

### Step 1: Create test file with setup
- Create `test/haul/tenant_isolation_test.exs`
- Implement helper functions for tenant creation and data seeding
- Setup block: provision 2 tenants, seed data, register on_exit cleanup
- Verify: `mix test test/haul/tenant_isolation_test.exs` compiles

### Step 2: Implement job isolation tests (3 tests)
- Query jobs as tenant A → assert only A's job returned
- Query jobs as tenant B → assert only B's job returned
- Create new job in A → query B → assert new job not in B
- Verify: all 3 pass

### Step 3: Implement content isolation tests (4 tests)
- SiteConfig: read in A → A's config; read in B → B's config
- Services: read in A → A's service titles; read in B → B's titles
- GalleryItems: read in A → only A's items
- Endorsements: read in A → only A's endorsements
- Verify: all 4 pass

### Step 4: Implement auth boundary test (1 test)
- User registered in A tries sign_in_with_password with tenant B context
- Assert error (not found / auth failure)
- Verify: passes

### Step 5: Implement missing tenant context test (1 test)
- Try Ash.read on Job without tenant option
- Assert error raised (Ash requires tenant for :context strategy resources)
- Verify: passes

### Step 6: Implement defense-in-depth test (1 test)
- Direct SQL: `SELECT * FROM "tenant_b_schema".jobs WHERE customer_name = 'A customer'`
- Assert empty result set
- Verify: passes

### Step 7: Full test suite verification
- Run `mix test` — all existing + new tests pass
- Verify test count increased by 10

## Testing Strategy
- All tests in single `async: false` module sharing one setup
- Total new tests: 10
- No mocking needed — uses real database with schema isolation
