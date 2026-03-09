# T-015-01 Research: Signup Page

## Existing Onboarding Pipeline

`Haul.Onboarding.run/1` orchestrates tenant provisioning:
1. Validate required fields (name, email)
2. Derive slug from business name (`derive_slug/1`)
3. Find or create Company (idempotent on slug)
4. Provision tenant schema (via `ProvisionTenant` change on Company create)
5. Seed default content from `priv/content/defaults/`
6. Update SiteConfig with phone, email, service_area
7. Find or create owner user (`:register_with_password` + role update to `:owner`)

The mix task generates a random temp password. For web signup, the user provides their own password.

## Authentication Flow

**LoginLive pattern** (`lib/haul_web/live/app/login_live.ex`):
- Resolves tenant from session (`tenant` or `tenant_slug` key)
- Calls `User |> Ash.Query.for_read(:sign_in_with_password, ...)` with tenant
- On success: gets `user.__metadata__.token`, stuffs into hidden form field
- Uses `phx-trigger-action` to POST to `AppSessionController.create`
- Controller stores `user_token` + `tenant` in session, redirects to `/app`

**Session creation** (`AppSessionController.create`):
```elixir
put_session(conn, :user_token, token)
put_session(conn, :tenant, tenant)
configure_session(renew: true)
redirect(to: ~p"/app")
```

Key insight: LiveView can't set session cookies directly. Must use `phx-trigger-action` to POST to a controller that sets the session, same as LoginLive.

## Router Structure

Public auth routes (no tenant hook, no auth):
```elixir
scope "/app", HaulWeb do
  pipe_through :browser
  live "/login", App.LoginLive
  post "/session", AppSessionController, :create
  delete "/session", AppSessionController, :delete
end
```

Signup route should go here — public, no tenant required.

## Company Resource

`Haul.Accounts.Company` (`lib/haul/accounts/company.ex`):
- Attributes: id, slug, name, timezone, subscription_plan, stripe_customer_id, domain
- Identity: `:unique_slug` on `[:slug]`
- `:create_company` action: accepts name/slug, auto-derives slug from name, runs `ProvisionTenant` change
- `ProvisionTenant` creates schema `"tenant_#{slug}"` and runs migrations

## User Resource

`Haul.Accounts.User`:
- `:register_with_password` — creates user with email/password, generates JWT token
- Policy: allows creation via `AshAuthenticationInteraction` check (no auth needed for registration)
- Token available at `user.__metadata__.token`
- `:update_user` — accepts role, phone, etc. (requires :owner actor)

## Slug Derivation

`Haul.Onboarding.derive_slug/1`:
```elixir
name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")
```

Slug uniqueness: Company has `:unique_slug` identity. Can check via `Ash.get(Company, slug: slug)`.

## Base Domain Config

`Application.get_env(:haul, :base_domain, "haulpage.com")` — used for site URL preview.

## UI Patterns

- Dark theme: `bg-background`, `text-foreground`, `border-border`, `bg-muted`
- Typography: `font-display` (Oswald) for headings
- Components: `<.input>`, `<.button>`, `<.form>` from CoreComponents
- Flash: `<HaulWeb.Layouts.flash_group flash={@flash} />`
- Page title: `assign(:page_title, "...")`

## Rate Limiting

No rate limiting library in deps. Options:
1. ETS-based counter (simple, no deps) — process-local, resets on restart
2. Add `{:hammer, "~> 6.2"}` or `{:ex_rated, "~> 2.1"}`
3. Plug-level check using `conn.remote_ip`

For MVP: ETS-based counter is simplest. Can upgrade later.

## Bot Prevention

No existing honeypot pattern. Standard approach:
- Hidden field with CSS `display: none` or `position: absolute; left: -9999px`
- If filled, silently reject (bots fill all fields)
- In LiveView: check in submit handler

## Redirect Target

Ticket says redirect to `/app/onboarding`. This route doesn't exist yet.
For now: redirect to `/app` (dashboard). The onboarding wizard is T-015-02.

## Dependencies

- T-012-01 (tenant plug) ✓ — TenantResolver exists
- T-014-01 (mix onboard task) — Onboarding module exists, status unclear but code is present

## Key Constraints

1. Signup creates tenant — cannot depend on existing tenant context
2. Must auto-login after signup (set session via controller POST)
3. Password provided by user (not temp-generated)
4. Need to modify `Haul.Onboarding` to accept password param (or bypass it for user creation)
5. Slug preview needs client-side derivation matching server-side logic
6. Rate limiting per IP — need to pass IP from conn to LiveView
