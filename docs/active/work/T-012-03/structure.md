# T-012-03 Structure: Wildcard DNS

## Files Modified

### 1. `fly.toml`
- Change `PHX_HOST` from `haul-page.fly.dev` to `haulpage.com`
- Add `BASE_DOMAIN = "haulpage.com"` env var

### 2. `config/runtime.exs`
- After the `BASE_DOMAIN` config block, add `check_origin` configuration
- When `BASE_DOMAIN` is set, configure endpoint with:
  ```
  check_origin: ["//*.{base_domain}", "//{base_domain}"]
  ```
- This goes in the general section (not prod-only), so it applies to all environments when BASE_DOMAIN is set

### 3. `docs/knowledge/operator-onboarding.md`
- Add new section "SaaS Platform DNS (Wildcard)" after current Step 7
- Document: DNS records, Fly wildcard cert, verification steps
- This is a one-time setup section, not per-operator

### 4. `test/haul_web/plugs/tenant_resolver_test.exs`
- Add test for check_origin pattern generation (if we extract it to a function)
- Actually: check_origin is pure Phoenix config, no custom function. Existing tests are sufficient.
- Add a test verifying bare domain + subdomain + unknown host behaviors are correct with wildcard context

## Files NOT Modified

| File | Reason |
|------|--------|
| `lib/haul_web/plugs/tenant_resolver.ex` | Already handles subdomains — no changes needed |
| `lib/haul_web/endpoint.ex` | check_origin is set via config, not in endpoint module |
| `lib/haul_web/router.ex` | Routes are tenant-aware already |
| `config/config.exs` | Defaults are fine (base_domain: "localhost" for dev) |
| `config/test.exs` | Already has base_domain: "haulpage.test" |

## Change Ordering

1. `fly.toml` — env var changes (deployed via `fly deploy`)
2. `config/runtime.exs` — check_origin config
3. `docs/knowledge/operator-onboarding.md` — documentation
4. Tests — verify existing behavior still passes

All changes are independent and can be committed atomically.

## Module Boundaries

No new modules. No interface changes. This is purely configuration.

## Architecture Notes

The wildcard DNS architecture:

```
DNS: *.haulpage.com → Fly shared IP
     haulpage.com   → Fly shared IP

Fly proxy: TLS termination (wildcard cert for *.haulpage.com)
         → forwards HTTP to app on port 4000

Phoenix Endpoint: receives request with Host header
                → check_origin validates WebSocket origins

Router → browser pipeline → TenantResolver plug
  → extracts subdomain from Host using BASE_DOMAIN
  → looks up Company by slug
  → sets conn.assigns.tenant + conn.assigns.current_tenant
```
