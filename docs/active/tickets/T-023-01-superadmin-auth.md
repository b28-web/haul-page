---
id: T-023-01
story: S-023
title: superadmin-auth
type: task
status: open
priority: high
phase: ready
depends_on: [T-024-04]
---

## Context

Add a dedicated `AdminUser` resource and a secure `/admin` route scope. The superadmin is the platform owner who needs to see all accounts and impersonate operators. `AdminUser` lives in the public schema, completely separate from tenant-scoped `User`.

Admin bootstrapping happens via env vars at startup — no mix tasks, no signup UI.

## Acceptance Criteria

### AdminUser resource

- New Ash resource `Haul.Accounts.AdminUser`:
  - Table `admin_users` in public schema (NOT tenant-scoped)
  - Attributes: `id` (uuid), `email` (ci_string, unique), `name` (string), `hashed_password`, `setup_completed` (boolean, default false), timestamps
  - AshAuthentication with password strategy
  - Tokens via `Haul.Accounts.AdminToken` (separate from tenant `Token`)
  - No policies beyond auth — if you're an AdminUser, you're authorized
  - Migration: `create table(:admin_users)` and `create table(:admin_tokens)`

### Bootstrap via env vars

- On application startup, check for `ADMIN_EMAIL` env var
- If set and no AdminUser exists with that email:
  - Create an AdminUser record with `setup_completed: false` and no password
  - Generate a cryptographically secure setup token (`:crypto.strong_rand_bytes(32) |> Base.url_encode64()`)
  - Store the token hash (SHA-256) on the AdminUser record (never store the raw token)
  - Log the one-time setup URL to stdout: `[admin] Setup link: https://host/admin/setup/<token>`
  - The raw token only ever appears in this log line
- If AdminUser already exists for that email: do nothing (idempotent startup)

### One-time setup link

- `GET /admin/setup/:token` route:
  - Hash the incoming token, compare against stored hash on the AdminUser with `setup_completed: false`
  - If match: render a "Set your password" form (password + confirmation)
  - If no match or already completed: 404
- `POST /admin/setup/:token`:
  - Validate password, hash it, set `hashed_password` and `setup_completed: true`
  - Clear the stored token hash (set to nil)
  - Redirect to `/admin/login` with flash "Account created. Please sign in."
  - The link is now dead — `setup_completed: true` and token hash is nil
- The setup link works exactly once. After use:
  - The token hash is wiped from the DB
  - `setup_completed` is true
  - Any further visits to `/admin/setup/*` return 404

### Login and session

- `/admin/login` — login page for AdminUser (separate from tenant `/app/login`)
  - Only works for AdminUsers with `setup_completed: true`
  - Session stored under `_admin_user_token` (different key from tenant `_user_token`)
  - No "sign up" link, no "forgot password" (use env var + restart to re-bootstrap)
- To reset: delete the AdminUser row (console/migration), restart with `ADMIN_EMAIL` set — new setup link is generated

### Route scope

- `HaulWeb.AdminAuthHooks.require_admin` on_mount hook:
  - Loads AdminUser from `_admin_user_token` session
  - Returns 404 (not 403) if not authenticated — don't reveal route exists
- `/admin` route scope:
  - `GET/POST /admin/setup/:token` (public, no auth)
  - `live "/login", Admin.LoginLive` (public, no auth)
  - `live_session :superadmin` with `require_admin` hook:
    - `live "/", Admin.DashboardLive` — placeholder
  - Uses a `:superadmin` layout

### Security

- Setup token: 32 bytes of `:crypto.strong_rand_bytes`, URL-safe base64 encoded
- Only the SHA-256 hash is stored in DB — timing-safe comparison via `:crypto.hash_equals` (or Plug.Crypto.secure_compare)
- Setup link is single-use: token hash cleared + `setup_completed` flag set atomically
- Admin session cookies use `_admin_user_token` — completely separate from tenant auth
- Tenant user sessions cannot access `/admin`; admin sessions cannot access `/app`
- AdminUser cannot be created via any HTTP endpoint (bootstrap only)

### Security tests

- Unauthenticated `/admin` returns 404
- Tenant user session does not grant `/admin` access
- Setup link works exactly once — second visit returns 404
- Invalid/random setup token returns 404
- AdminUser with `setup_completed: true` cannot use any setup link
- After setup, login works with correct password
- Admin session does not grant `/app` access
