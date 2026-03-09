# T-023-01 Structure: Superadmin Auth

## New Files

### Domain & Resources
- `lib/haul/admin.ex` — Ash domain registering AdminUser, AdminToken
- `lib/haul/admin/admin_user.ex` — Ash resource, AshAuthentication, password strategy, public schema
- `lib/haul/admin/admin_token.ex` — Ash token resource, public schema

### Bootstrap
- `lib/haul/admin/bootstrap.ex` — `ensure_admin!/0`: checks ADMIN_EMAIL, creates AdminUser, logs setup link

### Web: Auth Infrastructure
- `lib/haul_web/controllers/admin_session_controller.ex` — create/delete admin sessions
- `lib/haul_web/live/admin_auth_hooks.ex` — `on_mount(:require_admin, ...)` hook

### Web: LiveViews
- `lib/haul_web/live/admin/setup_live.ex` — One-time password setup (GET shows form, handles submit)
- `lib/haul_web/live/admin/login_live.ex` — Admin login form
- `lib/haul_web/live/admin/dashboard_live.ex` — Placeholder dashboard

### Web: Layout
- `lib/haul_web/components/layouts/superadmin.html.heex` — Minimal admin layout

### Migration
- `priv/repo/migrations/TIMESTAMP_create_admin_users.exs` — admin_users + admin_tokens tables (public schema)

### Tests
- `test/haul/admin/admin_user_test.exs` — Resource-level tests (creation, password, sign-in)
- `test/haul/admin/bootstrap_test.exs` — Bootstrap logic tests
- `test/haul_web/live/admin/setup_live_test.exs` — Setup flow tests
- `test/haul_web/live/admin/login_live_test.exs` — Login flow tests
- `test/haul_web/live/admin/security_test.exs` — All security acceptance criteria tests

## Modified Files

### `lib/haul/application.ex`
- Add `Haul.Admin.Bootstrap.ensure_admin!()` call after Repo starts

### `lib/haul_web/router.ex`
- Add `:admin_browser` pipeline (browser sans TenantResolver/EnsureChatSession)
- Add `/admin` scope with public and authenticated routes

### `lib/haul_web/components/layouts.ex`
- Add `embed_templates` already covers `layouts/*`, so just creating the template file is sufficient

### `config/config.exs`
- Register `Haul.Admin` domain in Ash config (if needed)

## Module Boundaries

```
Haul.Admin (domain)
├── Haul.Admin.AdminUser (resource — auth, password, attributes)
├── Haul.Admin.AdminToken (token resource)
└── Haul.Admin.Bootstrap (startup module — env var check, user creation, token generation)

HaulWeb
├── AdminSessionController (session create/delete)
├── AdminAuthHooks (on_mount :require_admin)
├── Admin.SetupLive (one-time setup)
├── Admin.LoginLive (login)
└── Admin.DashboardLive (placeholder)
```

## Key Interfaces

### AdminUser Resource
- `:sign_in_with_password` — AshAuthentication auto-generated
- `:create_bootstrap` — custom create action (no password, setup_completed: false)
- `:complete_setup` — custom update action (set password, setup_completed: true, clear token hash)

### Bootstrap Module
```elixir
Haul.Admin.Bootstrap.ensure_admin!() :: :ok | :noop
# Reads ADMIN_EMAIL, creates user if needed, logs setup URL
```

### AdminAuthHooks
```elixir
on_mount(:require_admin, params, session, socket) :: {:cont, socket} | {:halt, socket}
# Loads admin from session["_admin_user_token"], returns 404 on failure
```

## Database Schema (public)

### admin_users
- id: uuid PK
- email: citext, unique
- name: varchar
- hashed_password: varchar
- setup_token_hash: varchar (nullable — cleared after setup)
- setup_completed: boolean, default false
- inserted_at, updated_at: timestamps

### admin_tokens
- Standard AshAuthentication.TokenResource columns (auto-managed)
