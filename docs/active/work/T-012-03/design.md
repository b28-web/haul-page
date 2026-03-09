# T-012-03 Design: Wildcard DNS

## Problem

Operators need subdomains (`acme.haulpage.com`) that route to the shared Fly app without per-operator DNS changes. Currently:
- No `BASE_DOMAIN` is set in production
- `PHX_HOST` is `haul-page.fly.dev`
- No `check_origin` config (LiveView WebSockets will fail from subdomain origins)
- Runbook describes only per-operator Fly apps, not the shared SaaS model

## Approach: Minimal Config Changes

Since TenantResolver already handles subdomain routing, this ticket is primarily configuration:

### 1. fly.toml: Add BASE_DOMAIN

```toml
[env]
  PHX_HOST = "haulpage.com"
  BASE_DOMAIN = "haulpage.com"
  PORT = "4000"
```

**PHX_HOST change**: From `haul-page.fly.dev` to `haulpage.com`. This controls URL generation (e.g., in emails, redirects). The bare domain is correct — it's the canonical URL for the platform.

### 2. runtime.exs: Configure check_origin

Phoenix validates WebSocket origins against the configured host. With wildcard subdomains, we need to allow `*.haulpage.com` patterns.

**Option A: Wildcard pattern list**
```elixir
config :haul, HaulWeb.Endpoint,
  check_origin: ["//*.haulpage.com", "//haulpage.com"]
```

**Option B: Disable check_origin**
```elixir
config :haul, HaulWeb.Endpoint, check_origin: false
```

**Decision: Option A** — wildcard pattern. Option B is insecure. Phoenix supports `//` wildcard patterns natively. We also include the bare domain for the marketing page.

We must also allow custom domains. Since custom domains are dynamic (stored in DB), we can't enumerate them in config. Phoenix supports `check_origin: {module, function, args}` for dynamic checking, but that's heavier than needed. Instead, we allow `:conn` which checks against the request's host header:

Actually, re-examining: Phoenix `check_origin` with `:conn` would check against the `conn.host`, which is what we want — it matches the host the request came in on. But `:conn` was added in Phoenix 1.7+. Let's verify.

**Revised decision**: Use a pattern list for the known platform domain plus `:conn` is not a valid check_origin value. The MFA approach `{Module, :check_origin, []}` is the most flexible. But for now, since custom domains are a future concern (T-017), we keep it simple:

```elixir
check_origin: [
  "//*.#{base_domain}",
  "//#{base_domain}"
]
```

When `BASE_DOMAIN` is set, we build the pattern. When not set (dev/test), we skip it (Phoenix defaults work fine for localhost).

### 3. DNS Setup (Documented, Not Automated)

This is infrastructure config done once, not code. Document in the runbook:

1. Get Fly app IPs: `fly ips list`
2. At DNS registrar for `haulpage.com`:
   - `A` record: `haulpage.com` → Fly IPv4
   - `AAAA` record: `haulpage.com` → Fly IPv6
   - `A` record: `*.haulpage.com` → Fly IPv4
   - `AAAA` record: `*.haulpage.com` → Fly IPv6
3. Add wildcard cert: `fly certs add "*.haulpage.com"`
4. Add bare cert: `fly certs add "haulpage.com"`
5. Verify: `fly certs list`

### 4. Bare domain behavior

`haulpage.com` (no subdomain) → TenantResolver returns `nil` subdomain → fallback to operator config slug. This is the current behavior and is correct for now. When a marketing/signup page is added (T-015-03), it can check `conn.assigns.current_tenant == nil` to show the marketing page instead.

## Rejected Approaches

**Per-operator DNS records**: Requires manual work for each operator. The whole point of wildcard DNS is to avoid this.

**fly-proxy based routing**: Fly's proxy handles TLS termination. No need for application-level TLS or SNI routing.

**Dynamic check_origin MFA**: Overkill for now. Custom domains (T-017) will revisit this when needed.

## Risk Assessment

- **Low risk**: TenantResolver code is already tested and working
- **Medium risk**: DNS propagation delay when first configuring — not a code risk, operational
- **Low risk**: check_origin change is well-understood Phoenix config
