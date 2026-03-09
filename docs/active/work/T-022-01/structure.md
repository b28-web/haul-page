# T-022-01 Structure: ProxyTenantResolver Plug

## Files to Create

### `lib/haul_web/plugs/proxy_tenant_resolver.ex`

Module: `HaulWeb.Plugs.ProxyTenantResolver`

```
@behaviour Plug
init/1 → opts passthrough
call/2 →
  1. Read conn.path_params["slug"]
  2. Query Company by slug: Ash.Query.filter(slug == ^slug) |> Ash.read_one()
  3. If found:
     - assign current_tenant: company
     - assign tenant: "tenant_#{slug}"
     - assign proxy_slug: slug
     - assign is_platform_host: false
     - put_session "tenant_slug", slug
     - put_session "proxy_slug", slug
  4. If not found:
     - send_resp(404, "Tenant not found")
     - halt()
```

### `lib/haul_web/live/proxy_tenant_hook.ex`

Module: `HaulWeb.ProxyTenantHook`

```
on_mount(:resolve_tenant, _params, session, socket) →
  1. Read session["tenant_slug"]
  2. Read session["proxy_slug"]
  3. Load Company by slug (same as TenantHook)
  4. Assign current_tenant, tenant, proxy_slug on socket
  5. If no slug or company not found → halt with 404
```

### `test/haul_web/plugs/proxy_tenant_resolver_test.exs`

Tests:
- Resolves valid slug → sets current_tenant, tenant, proxy_slug
- Unknown slug → 404 response
- No slug → 404 response
- Session contains tenant_slug and proxy_slug after resolution

### `test/haul_web/live/proxy_tenant_hook_test.exs`

Tests:
- LiveView mount via proxy route → socket has tenant assigns + proxy_slug
- Unknown slug → 404

## Files to Modify

### `lib/haul_web/router.ex`

Add inside existing `dev_routes` guard:
1. `:proxy_browser` pipeline definition
2. `/proxy/:slug` scope with all public tenant routes

## Module Boundaries

```
ProxyTenantResolver
  └── reads path_params, queries Company, sets assigns
  └── no dependency on TenantResolver (parallel implementation)

ProxyTenantHook
  └── reads session (set by ProxyTenantResolver), queries Company, sets socket assigns
  └── no dependency on TenantHook (parallel implementation)

Router
  └── :proxy_browser pipeline (replaces TenantResolver with ProxyTenantResolver)
  └── /proxy/:slug scope mirrors / scope routes
```

## Ordering

1. ProxyTenantResolver plug (no deps)
2. ProxyTenantHook (no deps on plug, but logically paired)
3. Router changes (depends on both modules existing)
4. Tests (after all modules created)
