# T-012-01 Plan: Tenant Resolver Plug

## Step 1: Migration — add domain column to companies

- Create migration adding `domain` (nullable text) to `companies`
- Add unique index on `domain` (partial, where domain is not null)
- Run migration, verify it applies cleanly

## Step 2: Company resource — add domain attribute

- Add `attribute :domain, :string` (allow_nil? true, public? true)
- Add `identity :unique_domain, [:domain]`
- Update `:create_company` and `:update_company` to accept `:domain`
- Verify existing tests still pass

## Step 3: Config — base_domain setting

- Add `config :haul, :base_domain, "localhost"` to config.exs
- Add `BASE_DOMAIN` env var override in runtime.exs
- Add to test.exs: `config :haul, :base_domain, "haulpage.test"` (for test isolation)

## Step 4: TenantResolver plug — implementation

- Create `lib/haul_web/plugs/tenant_resolver.ex`
- Implement `init/1` and `call/2`
- Resolution chain: custom domain → subdomain → fallback
- Assign `current_tenant` and `tenant` to conn

## Step 5: Router integration

- Add `plug HaulWeb.Plugs.TenantResolver` to `:browser` pipeline
- Restructure API routes: places API gets tenant plug, webhooks do not
- Healthz stays outside tenant-aware pipelines

## Step 6: Tests

- Create `test/haul_web/plugs/tenant_resolver_test.exs`
- Test cases:
  1. Subdomain `joes-hauling.haulpage.test` → resolves to Joe's company
  2. Custom domain `www.joeshauling.com` → resolves to Joe's company
  3. Unknown host → fallback demo tenant
  4. Bare base domain → fallback demo tenant
  5. Tenant schema string is correctly derived
- Each test creates a Company via Ash, sets Host header, runs plug

## Step 7: Verify all existing tests pass

- Run full test suite
- Fix any breakage from router pipeline changes

## Testing Strategy

- Unit tests for the plug (ConnCase, direct plug invocation)
- No integration/browser tests in this ticket (T-012-05 covers that)
- Existing tests should not break — fallback behavior preserves current single-tenant mode
