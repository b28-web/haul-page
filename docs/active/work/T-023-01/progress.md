# T-023-01 Progress: Superadmin Auth

## Completed Steps

### Step 1: Admin Domain + Resources ✅
- Created `lib/haul/admin.ex` (domain)
- Created `lib/haul/admin/admin_user.ex` (resource with AshAuthentication)
- Created `lib/haul/admin/admin_token.ex` (token resource)
- Registered `Haul.Admin` in `config/config.exs` ash_domains
- Compiles clean

### Step 2: Migration ✅
- Generated migration `20260309182942_create_admin_users.exs`
- Creates `admin_users` and `admin_tokens` tables in public schema
- Migration ran successfully

### Step 3: Bootstrap Module ✅
- Created `lib/haul/admin/bootstrap.ex`
- Added `ensure_admin!()` call in `Application.start/2`
- Generates secure random token, stores SHA-256 hash, logs setup URL

### Step 4: Router + Pipeline ✅
- Added `:admin_browser` pipeline (browser sans TenantResolver/EnsureChatSession)
- Added `/admin` scope with public and authenticated routes
- Used `HaulWeb.Plugs.RequireAdmin` plug for HTTP-level 404 on unauthenticated access

### Step 5: Admin Session Controller ✅
- Created `lib/haul_web/controllers/admin_session_controller.ex`
- Stores `_admin_user_token` in session (separate from tenant `user_token`)

### Step 6: Admin Auth Hooks ✅
- Created `lib/haul_web/live/admin_auth_hooks.ex`
- Verifies JWT, loads AdminUser, checks setup_completed
- Created `lib/haul_web/plugs/require_admin.ex` for HTTP-level 404

### Step 7: Setup LiveView ✅
- Created `lib/haul_web/live/admin/setup_live.ex`
- Validates token hash, renders password form, completes setup atomically

### Step 8: Login LiveView ✅
- Created `lib/haul_web/live/admin/login_live.ex`
- Uses AshAuthentication sign_in_with_password, trigger_submit pattern

### Step 9: Dashboard + Layout ✅
- Created `lib/haul_web/live/admin/dashboard_live.ex` (placeholder)
- Created `lib/haul_web/components/layouts/superadmin.html.heex`

### Step 10: Security Tests ✅
- All acceptance criteria covered in `test/haul_web/live/admin/security_test.exs`
- Bootstrap tests in `test/haul/admin/bootstrap_test.exs`
- 15 tests total, all passing

### Step 11: Full Suite ✅
- 771 tests, 0 failures (1 excluded)

## Deviations from Plan
- Added `HaulWeb.Plugs.RequireAdmin` plug for HTTP-level 404 responses (on_mount hooks can only redirect, not return status codes)
- Combined setup/login/security tests into a single security_test.exs file for cohesion
- AdminUser :create_bootstrap action uses an argument `setup_token_hash_value` to set the sensitive attribute
