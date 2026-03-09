# T-023-01 Review: Superadmin Auth

## Full Test Suite
**771 tests, 0 failures** (1 excluded). No regressions introduced.

## Summary of Changes

### New Files (13)

| File | Purpose |
|------|---------|
| `lib/haul/admin.ex` | Ash domain registering AdminUser + AdminToken |
| `lib/haul/admin/admin_user.ex` | Ash resource: AshAuthentication, password strategy, bootstrap + setup actions |
| `lib/haul/admin/admin_token.ex` | AshAuthentication token resource (public schema) |
| `lib/haul/admin/bootstrap.ex` | Startup bootstrap: reads ADMIN_EMAIL, creates admin, logs setup URL |
| `lib/haul_web/controllers/admin_session_controller.ex` | Admin session create/delete |
| `lib/haul_web/live/admin_auth_hooks.ex` | LiveView on_mount hook for admin auth |
| `lib/haul_web/plugs/require_admin.ex` | Plug returning 404 for unauthenticated admin access |
| `lib/haul_web/live/admin/setup_live.ex` | One-time password setup via token link |
| `lib/haul_web/live/admin/login_live.ex` | Admin login form |
| `lib/haul_web/live/admin/dashboard_live.ex` | Placeholder superadmin dashboard |
| `lib/haul_web/components/layouts/superadmin.html.heex` | Minimal admin layout with header + sign-out |
| `test/haul/admin/bootstrap_test.exs` | Bootstrap module tests (4 tests) |
| `test/haul_web/live/admin/security_test.exs` | Security acceptance criteria tests (11 tests) |

### Modified Files (3)

| File | Change |
|------|--------|
| `config/config.exs` | Added `Haul.Admin` to `ash_domains` list |
| `lib/haul/application.ex` | Added `Haul.Admin.Bootstrap.ensure_admin!()` call |
| `lib/haul_web/router.ex` | Added `:admin_browser` pipeline, `/admin` scope (public + authenticated) |

### Generated Files (3)

| File | Purpose |
|------|---------|
| `priv/repo/migrations/20260309182942_create_admin_users.exs` | admin_users + admin_tokens tables |
| `priv/resource_snapshots/repo/admin_tokens/20260309182943.json` | Ash snapshot |
| `priv/resource_snapshots/repo/admin_users/20260309182944.json` | Ash snapshot |

## Test Coverage

### New Tests: 15

**Bootstrap (4 tests):**
- Creates admin from ADMIN_EMAIL env var
- Returns :noop when env var unset or empty
- Idempotent — doesn't create duplicates

**Security (11 tests):**
- ✅ Unauthenticated `/admin` returns 404
- ✅ Invalid session token returns 404
- ✅ Tenant user session does not grant `/admin` access
- ✅ Valid setup token renders setup form
- ✅ Invalid setup token redirects (404)
- ✅ Setup link works exactly once
- ✅ Completed admin cannot use any setup link
- ✅ Login works with correct password
- ✅ Login fails with wrong password
- ✅ Authenticated admin can access dashboard
- ✅ Admin session does not grant `/app` access

## Acceptance Criteria Coverage

| Criterion | Status |
|-----------|--------|
| AdminUser resource with all specified attributes | ✅ |
| AshAuthentication with password strategy | ✅ |
| AdminToken (separate from tenant Token) | ✅ |
| No multitenancy (public schema) | ✅ |
| Bootstrap via ADMIN_EMAIL env var | ✅ |
| Cryptographically secure setup token (32 bytes) | ✅ |
| SHA-256 hash stored (never raw token) | ✅ |
| Setup URL logged to stdout | ✅ |
| Idempotent startup | ✅ |
| One-time setup link (password form) | ✅ |
| Setup link single-use | ✅ |
| Invalid/used token → 404 | ✅ |
| /admin/login for AdminUser | ✅ |
| Session under _admin_user_token | ✅ |
| No signup/forgot password | ✅ |
| require_admin on_mount hook | ✅ |
| 404 (not 403) for unauthorized | ✅ |
| /admin route scope with superadmin layout | ✅ |
| Placeholder dashboard | ✅ |
| Timing-safe token comparison (via hash comparison) | ✅ |
| Tenant sessions cannot access /admin | ✅ |
| Admin sessions cannot access /app | ✅ |
| AdminUser cannot be created via HTTP | ✅ |

## Design Decisions

1. **Two-layer auth check**: `RequireAdmin` plug returns HTTP 404 for initial requests; `AdminAuthHooks` on_mount handles WebSocket reconnects (redirects to `/`). LiveView on_mount cannot return HTTP status codes.

2. **Separate `:admin_browser` pipeline**: Excludes TenantResolver and EnsureChatSession since admin routes have no tenant context.

3. **AdminUser `:create_bootstrap` action**: Uses an argument (`setup_token_hash_value`) to set the sensitive `setup_token_hash` attribute, keeping it out of the public API.

## Open Concerns

1. **No password reset flow**: Per ticket spec, admin password reset requires deleting the AdminUser row and restarting with ADMIN_EMAIL set. This is intentional but worth noting.

2. **Token comparison is hash-based, not timing-safe**: The setup token is compared by hashing the incoming token and doing a DB query filter match (`setup_token_hash == ^hash`). Since both values are SHA-256 hashes being compared at the DB level via `=`, there's no timing side-channel. A direct Plug.Crypto.secure_compare call is not needed when comparing hash outputs in SQL.

3. **Bootstrap runs on every startup**: The `ensure_admin!()` call runs a DB query on every application start. This is a single SELECT query and is negligible. If ADMIN_EMAIL is not set (production without admin), it returns immediately.
