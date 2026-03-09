# T-012-03 Review: Wildcard DNS

## Summary

Configured wildcard DNS support for `*.haulpage.com` on the shared Fly app. This is primarily a configuration and documentation ticket — the TenantResolver code was already functional.

## Changes

### Modified Files

| File | Change |
|------|--------|
| `fly.toml` | `PHX_HOST` → `haulpage.com`, added `BASE_DOMAIN = "haulpage.com"` |
| `config/runtime.exs` | Added `check_origin` wildcard pattern when `BASE_DOMAIN` is set |
| `docs/knowledge/operator-onboarding.md` | Added "SaaS Platform DNS (One-Time Setup)" section |

### No New Files Created (code)

### No Files Deleted

## Acceptance Criteria Assessment

| Criterion | Status | Notes |
|-----------|--------|-------|
| Wildcard DNS record: `*.haulpage.com` → Fly app IP | **Documented** | DNS setup documented in runbook; actual DNS config is manual infrastructure work |
| Fly.io wildcard TLS certificate configured | **Documented** | `fly certs add` commands documented in runbook |
| Bare `haulpage.com` serves the marketing/signup page | **Ready** | TenantResolver falls back to demo tenant for bare domain; marketing page is T-015-03 |
| `anything.haulpage.com` hits the app and is resolved by TenantResolver | **Ready** | TenantResolver already handles subdomain → Company lookup; `BASE_DOMAIN` now configured |
| Document the DNS setup in the onboarding runbook | **Done** | Full section added with IP lookup, DNS records, cert commands, and verification |

## Test Coverage

- **14 existing tests** in `tenant_resolver_test.exs` cover subdomain resolution, custom domain resolution, fallback behavior, session storage, and `extract_subdomain/2`
- **No new tests needed** — the changes are configuration (env vars, check_origin) not logic
- **Full suite**: 250 tests, 1 pre-existing flaky failure (QR controller concurrency issue, not related)

## Open Concerns

1. **DNS not yet configured**: The actual DNS records and Fly certificates are infrastructure work done once by the developer. The code and docs are ready; the DNS step is manual.

2. **Flaky QR test**: `test/haul_web/controllers/qr_controller_test.exs:61` fails intermittently in full suite runs but passes in isolation. Pre-existing issue, not caused by this ticket.

3. **Custom domain check_origin**: The current `check_origin` pattern only covers `*.haulpage.com`. When custom domains are added (T-017), the check_origin config will need to be updated to use an MFA callback that also validates against the Company `domain` field. This is a known future concern.

4. **Bare domain marketing page**: Currently `haulpage.com` falls back to the demo tenant (junk-and-handy). T-015-03 will add a proper marketing/signup landing page that checks `conn.assigns.current_tenant == nil`.

## What a Reviewer Should Know

- This is a **low-risk** change: 3 lines of config, 2 lines of env vars, ~60 lines of documentation
- The TenantResolver was built in T-012-01 and is already tested — this ticket only configures the infrastructure around it
- After merging, the developer needs to manually run the DNS setup steps from the runbook
- The `check_origin` change is important for LiveView — without it, WebSocket connections from `slug.haulpage.com` would be rejected by Phoenix's CSRF origin check
