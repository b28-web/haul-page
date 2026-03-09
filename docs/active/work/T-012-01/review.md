# T-012-01 Review: Tenant Resolver Plug

## Summary

Built `HaulWeb.Plugs.TenantResolver` — the foundational plug for multi-tenant routing. Resolves tenant context from HTTP Host header using a three-step chain: custom domain → subdomain → fallback demo tenant. Added `domain` attribute to Company resource with migration.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul_web/plugs/tenant_resolver.ex` | Plug that resolves tenant from Host header |
| `test/haul_web/plugs/tenant_resolver_test.exs` | 12 tests covering all resolution paths |
| `priv/repo/migrations/20260309022659_add_domain_to_companies.exs` | Adds `domain` column to companies |
| `priv/resource_snapshots/repo/companies/20260309022700.json` | Ash resource snapshot |

## Files Modified

| File | Changes |
|------|---------|
| `lib/haul/accounts/company.ex` | Added `domain` attribute, `unique_domain` identity, accept in create/update |
| `lib/haul_web/router.ex` | Added TenantResolver to `:browser` pipeline, new `:api_with_tenant` pipeline |
| `config/config.exs` | Added `:base_domain` config (default: `"localhost"`) |
| `config/runtime.exs` | Added `BASE_DOMAIN` env var support |
| `config/test.exs` | Set `:base_domain` to `"haulpage.test"` |

## Test Coverage

- **12 new tests**, all passing
- **Subdomain resolution:** resolves correct company, handles multiple companies
- **Custom domain resolution:** resolves by domain field, prioritizes over subdomain
- **Fallback behavior:** unknown host, bare base domain, localhost, unknown subdomain → all fall back to demo tenant
- **Unit tests:** `extract_subdomain/2` function tested directly
- **Full suite:** 224 tests, 0 failures (baseline was 212)

## Acceptance Criteria Status

| Criteria | Status |
|----------|--------|
| Check Host for custom domain → Company by `domain` | ✅ |
| Extract subdomain → Company by `slug` | ✅ |
| Fallback for bare/unknown host → demo tenant | ✅ |
| Sets `conn.assigns.current_tenant` | ✅ |
| Sets Ash tenant context on conn | ✅ (`conn.assigns.tenant`) |
| Company gains `slug` (already existed), `domain` | ✅ |
| Migration adds `domain` column + unique index | ✅ |
| Plug in router pipeline before routes | ✅ |
| Subdomain resolution test | ✅ |
| Custom domain resolution test | ✅ |
| Unknown host fallback test | ✅ |
| Cross-tenant isolation test | Deferred to T-012-04 |

## Design Decisions

1. **Fallback = demo tenant, not 404** — preserves backwards compatibility during single-to-multi-tenant transition. Bare domain, localhost, and unknown hosts all gracefully fall back to the operator config slug.

2. **`current_tenant` = Company struct, `tenant` = schema string** — separates the business entity from the Ash tenant identifier. Controllers can access Company fields; Ash operations use the schema string.

3. **Plug in router pipeline, not endpoint** — healthz and webhook routes don't need tenant context. Only `:browser` and `:api_with_tenant` pipelines resolve tenant.

4. **`Ash.Query.filter` + `Ash.read_one`** — `Ash.read_one` doesn't accept a `filter:` keyword option. Must build a query with `Ash.Query.filter/2` first.

## Open Concerns

1. **No caching** — every request queries the Company table. Acceptable for now (table is tiny), but may want ETS cache if this becomes a bottleneck at scale.

2. **LiveView socket tenant** — T-012-02 handles propagating tenant context through LiveView socket connections. Currently LiveViews still use `ContentHelpers.resolve_tenant/0`.

3. **`subdomain_url` computed attribute** — ticket mentions this but it's not critical for the plug to function. Can be added in a follow-up.

4. **Wildcard DNS** — T-012-03 handles DNS configuration for `*.haulpage.com`. The plug is ready for it.

5. **Downstream migration** — existing controllers/LiveViews still call `ContentHelpers.resolve_tenant/0` instead of reading from conn assigns. Gradual migration needed (T-012-02 and beyond).
