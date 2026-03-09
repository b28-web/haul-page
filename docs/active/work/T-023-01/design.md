# T-023-01 Design: Superadmin Auth

## Decision 1: AshAuthentication vs Manual Auth for AdminUser

### Option A: Full AshAuthentication with password strategy
- Pros: Built-in password hashing, JWT tokens, sign_in action, consistent with User
- Cons: Brings multi-tenant token machinery we don't need. The bootstrap flow (env var → setup token → one-time password set) is completely custom either way. AshAuthentication's `:register_with_password` expects HTTP-driven registration which conflicts with the bootstrap requirement.

### Option B: AshAuthentication for sign-in only, manual bootstrap
- Pros: Gets the sign_in_with_password action for free, JWT token for session
- Cons: AshAuthentication's token resource adds complexity. We'd need to wire up AdminToken separately from tenant Token.

### Option C: Manual auth (Bcrypt + session token, no AshAuthentication)
- Pros: Simple, no multi-tenant token table needed. `Bcrypt.hash_pwd_salt/1` and `Bcrypt.verify_pass/2` are trivial. Session uses a random token stored in DB, not JWT.
- Cons: Diverges from User pattern. Must implement password verification manually.

### Decision: Option B — AshAuthentication for sign-in, manual bootstrap

The ticket explicitly says "AshAuthentication with password strategy" and "Tokens via Haul.Accounts.AdminToken". We use AshAuthentication for the standard sign-in flow and JWT session management, but implement the bootstrap/setup-token flow as custom Ash actions and a standalone module. This gives us:
- Standard `sign_in_with_password` action
- JWT-based session tokens (consistent with User)
- AdminToken resource for token storage
- Custom actions for bootstrap and setup

## Decision 2: Domain Organization

### Option A: Add to Haul.Accounts domain
- Simpler, fewer files
- Mixes tenant-scoped and public-schema resources in same domain

### Option B: New Haul.Admin domain
- Clean separation of concerns
- AdminUser is fundamentally different (public schema, platform-level)

### Decision: Option B — New Haul.Admin domain

AdminUser has no relationship to tenant-scoped Users. Separate domain keeps the boundary clear. Files: `lib/haul/admin.ex`, `lib/haul/admin/admin_user.ex`, `lib/haul/admin/admin_token.ex`.

## Decision 3: Setup Token Storage

### Option A: Separate setup_tokens table
- More tables, more migrations

### Option B: Columns on admin_users table
- `setup_token_hash` (binary) + `setup_completed` (boolean)
- Simple, atomic — clear token and set completed in one update

### Decision: Option B — Columns on admin_users

The ticket specifies `setup_completed` as an attribute on AdminUser. Adding `setup_token_hash` alongside it is the simplest approach. The token is single-use and ephemeral.

## Decision 4: Session Key Strategy

The ticket specifies `_admin_user_token` session key. This is stored in the same cookie (`_haul_key`) but under a different key within the session map. Admin and tenant sessions coexist in the same cookie but don't interfere.

## Decision 5: Bootstrap Trigger

### Option A: Startup task in Application.start
- Runs before endpoint starts serving
- Clean, happens once

### Option B: Separate GenServer
- Overkill for a one-time check

### Decision: Option A — Bootstrap in Application.start

Add `Haul.Admin.Bootstrap.ensure_admin!()` call in `Application.start/2` after Repo is started but before Endpoint. This checks ADMIN_EMAIL env var and creates/logs setup link if needed.

## Decision 6: Router Structure

```
scope "/admin", HaulWeb do
  pipe_through [:browser]   # Need a modified browser pipeline without TenantResolver

  # Public admin routes (no auth)
  live "/setup/:token", Admin.SetupLive
  live "/login", Admin.LoginLive
  post "/session", AdminSessionController, :create
  delete "/session", AdminSessionController, :delete

  # Authenticated admin routes
  live_session :superadmin,
    on_mount: [{HaulWeb.AdminAuthHooks, :require_admin}],
    layout: {HaulWeb.Layouts, :superadmin} do
    live "/", Admin.DashboardLive
  end
end
```

Need a separate pipeline for admin routes that skips TenantResolver and EnsureChatSession (admin routes don't need tenant context).

## Decision 7: Admin Browser Pipeline

Create `:admin_browser` pipeline that includes everything from `:browser` except TenantResolver and EnsureChatSession. Admin routes have no tenant context.

## Security Design

1. **Setup token**: 32 bytes from `:crypto.strong_rand_bytes/1`, base64url encoded
2. **Storage**: SHA-256 hash of raw token stored in `setup_token_hash` column
3. **Comparison**: `Plug.Crypto.secure_compare/2` for timing-safe comparison
4. **Single-use**: Atomic update sets `setup_completed: true` + clears `setup_token_hash` to nil
5. **Session isolation**: `_admin_user_token` key in session, separate hooks
6. **404 on failure**: All admin auth failures return 404, not 403/401
