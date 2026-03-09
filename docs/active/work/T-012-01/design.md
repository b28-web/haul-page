# T-012-01 Design: Tenant Resolver Plug

## Decision: Router Pipeline Plug with Host Header Parsing

### Approach

A Plug module `HaulWeb.Plugs.TenantResolver` inserted into the `:browser` and `:api` pipelines (but NOT healthz/webhook scopes). Resolution order:

1. **Custom domain match** — full Host header → `Ash.get(Company, domain: host)`
2. **Subdomain match** — strip base domain suffix → `Ash.get(Company, slug: subdomain)`
3. **Fallback** — use operator config slug as demo tenant (graceful degradation, not 404)

### Why This Approach

**Router pipeline vs endpoint-level plug:**
- Endpoint plug would run on every request including healthz, static files, webhooks
- Router pipeline gives per-scope control — only tenant-scoped routes get the plug
- Healthz and webhook routes work without tenant context (as they do today)

**Fallback to demo tenant vs 404:**
- During transition from single-tenant to multi-tenant, bare domain access must keep working
- Existing bookmarks, QR codes, and links target the bare domain
- Demo tenant = operator config slug, which is how single-tenant mode works today
- 404 for unknown hosts would break backwards compatibility

**Company lookup strategy:**
- Use default `:read` action with Ash filters (no new custom actions needed)
- `Ash.read_one(Company, filter: [domain: host])` for custom domain
- `Ash.read_one(Company, filter: [slug: subdomain])` for subdomain
- Company is in public schema — no tenant context needed for lookup

### Alternatives Rejected

**A. Path-based tenancy (`/t/:slug/...`):**
- Breaks all existing URLs and QR codes
- Ugly for customer-facing pages
- Rejected: Host-based is required by the spec

**B. Database-backed domain registry (separate table):**
- Over-engineering for current needs
- Company already has slug; adding domain is sufficient
- Rejected: YAGNI — add complexity when needed

**C. Caching layer (ETS/ConCache):**
- Premature optimization — Company table will be tiny (dozens of rows)
- Adds complexity and cache invalidation concerns
- Rejected: Direct DB lookup is fine for now

### Schema Changes

**Company resource — add `domain` attribute:**
```elixir
attribute :domain, :string do
  allow_nil? true
  public? true
end
```

**New identity:**
```elixir
identity :unique_domain, [:domain]
```

**Migration:** Add `domain` column (nullable text) + unique index.

**Update `:update_company` action** to accept `:domain`.

### Config Changes

**Base domain config** (`config :haul, :base_domain`):
- Default: `"localhost"` in config.exs
- Runtime: `BASE_DOMAIN` env var (e.g., `"haulpage.com"`)
- Used to strip subdomain from Host header

### Plug Behavior

```
Host: "www.joeshauling.com"
  → strip port → "www.joeshauling.com"
  → check custom domain → Company found → assign

Host: "joes-hauling.haulpage.com"
  → strip port → "joes-hauling.haulpage.com"
  → no custom domain match
  → strip base domain → "joes-hauling"
  → lookup by slug → Company found → assign

Host: "haulpage.com" (bare)
  → no custom domain match
  → no subdomain (host == base_domain)
  → fallback → demo tenant

Host: "localhost:4000" (dev)
  → strip port → "localhost"
  → no custom domain match
  → host == base_domain → fallback → demo tenant
```

### Assigns

- `conn.assigns.current_tenant` — Company struct (or nil for fallback)
- `conn.assigns.tenant` — schema string `"tenant_{slug}"` for Ash operations
- Both set by the plug, available to all downstream controllers/LiveViews

### Impact on Existing Code

- Downstream code currently calls `ContentHelpers.resolve_tenant()` — can gradually migrate to read from conn assigns
- No breaking changes: fallback behavior preserves current single-tenant behavior
- T-012-02 will handle LiveView socket tenant propagation
