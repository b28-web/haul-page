# T-023-03 Design: Impersonation

## Core Problem

Admin clicks "Impersonate" on account detail → sees `/app` as that tenant. Must work across LiveView session boundaries, maintain security, auto-expire, and be auditable.

## Approach: Session-Based Impersonation with Admin Auth Bypass

### How It Works

1. **Start**: Admin clicks "Impersonate" on AccountDetailLive → POST to `/admin/impersonate/:slug` (controller action, not LiveView event). Controller:
   - Validates admin session (RequireAdmin already ran in pipeline)
   - Stores `impersonating_slug`, `impersonating_since` (DateTime.utc_now ISO8601), `real_admin_id` in session
   - Logs `impersonation_start` event
   - Redirects to `/app`

2. **During**: Modified plugs/hooks detect impersonation:
   - TenantResolver checks session for `impersonating_slug` before host-based resolution
   - AuthHooks bypasses user JWT check when impersonation keys present + valid admin session exists
   - RequireAdmin blocks `/admin` routes during impersonation (returns 404)
   - Banner rendered in admin layout showing tenant name + time remaining + exit link

3. **Exit**: Admin clicks "Exit" → POST to `/admin/exit-impersonation` (controller action). Controller:
   - Clears `impersonating_slug`, `impersonating_since`, `real_admin_id` from session
   - Logs `impersonation_end` event
   - Redirects to `/admin/accounts`

4. **Expiry**: Checked on every request by TenantResolver plug and by AuthHooks:
   - Parse `impersonating_since`, compare to now
   - If > 1 hour: clear keys, log `impersonation_expired`, redirect to `/admin` with flash

### Why Controller Actions (Not LiveView Events)

- Impersonate/exit cross LiveView session boundaries (`:superadmin` → `:authenticated` and back)
- LiveView events can't redirect across live_session boundaries
- Controller actions modify session and redirect cleanly
- Start route goes through `admin_browser` + RequireAdmin pipeline (already authenticated)
- Exit route also goes through `admin_browser` + RequireAdmin — but RequireAdmin will block during impersonation. **Solution**: Exit route is in the public `/admin` scope (before RequireAdmin), but validates `_admin_user_token` manually.

### Auth Bypass During Impersonation

AuthHooks normally requires `user_token` + `tenant` in session. During impersonation, there's no valid tenant user JWT. Options:

**Option A: Skip AuthHooks entirely, use admin session instead**
- AuthHooks checks for impersonation keys + validates admin JWT
- Sets `current_user` to a synthetic/nil value, `current_company` from impersonated slug
- Pro: Simple, no fake tokens
- Con: `current_user` is nil — any code assuming a User struct will break

**Option B: Create a "virtual" user assignment**
- AuthHooks loads the first owner user from the impersonated tenant
- Sets `current_user` to that user (read-only context)
- Pro: App code works unchanged
- Con: Misrepresents who is acting — but ticket says "actor: admin_user in metadata"

**Decision: Option A with nil current_user**
- Set `current_user` to nil, `current_company` to the impersonated Company
- App LiveViews that reference `@current_user.email` in templates need guards (`:if` checks)
- But during impersonation the layout is different (has banner), so we control what renders
- The ticket explicitly says "All Ash actions during impersonation are tagged with actor: admin_user" — this confirms no fake user
- We assign `current_admin` so the banner can show admin info
- We assign `impersonating: true` flag for conditional rendering

### Banner Placement

The banner must appear on every page during impersonation. During impersonation, admin sees `/app` routes which use `admin.html.heex` layout. Options:

**Option A: Modify admin.html.heex** — add banner conditionally when `@impersonating` is set
**Option B: Modify root.html.heex** — appears even outside live_session
**Option C: New layout for impersonation**

**Decision: Option A** — Inject banner at top of `admin.html.heex` when `@impersonating` assign is truthy. Simple, contained, works with all `/app` LiveViews.

### Privilege Stacking Prevention

RequireAdmin plug and AdminAuthHooks both check for `impersonating_slug` in session. If present:
- RequireAdmin returns 404 (blocks all `/admin` routes)
- AdminAuthHooks returns halt + redirect (blocks LiveView mounts)
- This prevents accessing admin panel while impersonating

### Audit Logging

Use `Logger.info/2` with structured metadata. Pattern:
```elixir
Logger.info("Impersonation started",
  event: "impersonation_start",
  admin_user_id: admin.id,
  admin_email: admin.email,
  target_slug: slug,
  timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
)
```

Three events: `impersonation_start`, `impersonation_end`, `impersonation_expired`.

### Session Cleanup on Admin Logout

AdminSessionController.delete/2 already clears `_admin_user_token`. Add clearing of impersonation keys too. This invalidates impersonation if admin logs out.

### Impersonation Helper Module

New module `HaulWeb.Impersonation` with:
- `active?/1` — checks session/assigns for active impersonation
- `expired?/1` — checks if impersonation has exceeded 1 hour
- `remaining_minutes/1` — time remaining for banner display
- `start_session/3` — sets session keys + logs
- `end_session/2` — clears session keys + logs
- `expire_session/2` — clears keys + logs expiry + adds flash

Centralizes logic, avoids duplication across plugs/hooks/controllers.

## Rejected Alternatives

### Separate impersonation cookie
- Adds complexity, same session cookie works fine with namespaced keys
- Admin and impersonation state naturally live together

### LiveView event for impersonate button
- Can't cross live_session boundaries
- Controller redirect is the correct pattern

### Proxy-style impersonation (rewrite to /proxy/:slug/app)
- Proxy routes are dev-only
- Would require duplicating all /app routes
- Session-based approach is cleaner

### Fake user token generation
- Security risk: minting real JWTs for users the admin isn't
- Ticket explicitly calls for admin_user as actor
- Over-engineered for read-only viewing

## Route Changes

Add to public `/admin` scope (no RequireAdmin):
- `POST /admin/exit-impersonation` → AdminSessionController.exit_impersonation

Add to authenticated `/admin` scope (with RequireAdmin):
- `POST /admin/impersonate/:slug` → AdminSessionController.impersonate

## Security Test Coverage

1. Start impersonation sets correct session keys
2. Banner displays during impersonation with correct info
3. `/admin` routes return 404 during impersonation
4. Impersonation expires after 1 hour
5. Exit clears keys and redirects
6. Tenant users cannot set impersonation keys (no admin session → keys ignored)
7. Admin logout clears impersonation
8. Invalid slug returns error
