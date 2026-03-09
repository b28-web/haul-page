# T-004-01 Research: Company & User Resources

## Current State

### Ash Ecosystem (Installed, Unused)
- ash 3.19.3, ash_postgres 2.7.0, ash_authentication 4.13.7
- bcrypt_elixir 3.3.2 (transitive dep from ash_authentication)
- ash_phoenix 2.3.20, ash_paper_trail 0.5.7, ash_archival 2.0.3
- No Ash resources, domains, or policies defined anywhere in `lib/`

### Database Layer
- `Haul.Repo` — bare Ecto.Repo, `otp_app: :haul`, Postgres adapter
- Zero migrations in `priv/repo/migrations/`
- Config: `ecto_repos: [Haul.Repo]`, `generators: [timestamp_type: :utc_datetime]`
- Dev DB: `haul_dev` on localhost, test: `haul_test` with SQL sandbox
- `Haul.DataCase` — sets up SQL sandbox per test, provides `errors_on/1` helper

### Web Layer
- Router: two scopes — public (`/healthz`, `/`) and dev dashboard
- No auth pipelines, no `/app` scope, no LiveView routes
- `HaulWeb` module defines `:controller`, `:live_view`, `:html` macros
- No plugs for session-based auth or tenant context

### Application Supervisor
- Children: Telemetry, Repo, DNSCluster, PubSub, Endpoint
- No AshAuthentication supervisor or Ash domain registry

### Mailer
- `Haul.Mailer` — Swoosh with Local adapter (dev), ready for magic link emails

## Ash 3.x Architecture (v3.19)

### Domain Pattern
Ash 3.x uses `Ash.Domain` (not `Ash.Api`). A domain:
- Declares `resources` it manages
- Is the entry point for all operations (`Ash.read!/2`, `Ash.create!/2`)
- Must be listed in config under `:ash, :domains`

### Resource Pattern
Resources use `Ash.Resource` with:
- `postgres` block for table name, repo, schema (for multi-tenancy)
- `attributes` block with typed fields
- `actions` block with named CRUD operations
- `policies` block for authorization
- `identities` for unique constraints

### AshPostgres Multi-Tenancy (`:context` strategy)
- Resource declares `multitenancy strategy: :context` in `postgres` block
- Tenant is a Postgres schema name (e.g., `"tenant_demo_hauling"`)
- Set via `Ash.read!(Resource, tenant: "schema_name")` or query option
- Migrations create tables in `public` schema; tenant schemas get them via `mix ash_postgres.migrate --tenants`
- Company resource itself lives in `public` schema (it IS the tenant root)
- User resource lives in tenant schemas (one users table per company schema)

### AshAuthentication (v4.13)
- `use AshAuthentication` in the User resource
- Strategies: `authentication.strategies.password` and `authentication.strategies.magic_link`
- Password strategy uses bcrypt (already available)
- Magic link sends a token via email (needs `Haul.Mailer`)
- Generates tokens (needs a `tokens` resource or config)
- Provides `AshAuthentication.Plug` for session management
- `AshAuthentication.Phoenix` provides route helpers and LiveView components

### AshAuthentication Token Storage
- AshAuthentication requires a token resource for magic links and revocation
- Token resource stores JWTs, expiry, purpose (magic link, password reset, etc.)
- Must be in the same domain or accessible to the auth system

## Constraints & Boundaries

### Company Resource (Public Schema)
- NOT multi-tenant — it IS the tenant registry
- Fields: id (UUID), slug, name, timezone, subscription_plan, stripe_customer_id
- `slug` is the tenant identifier used to derive schema names
- Creating a company must provision a new Postgres schema
- Lives in `public.companies` table

### User Resource (Tenant Schema)
- Multi-tenant via `:context` strategy
- Fields: id, email, hashed_password, name, role, phone, active, company_id
- `company_id` is redundant with tenancy but useful for cross-tenant admin queries
- AshAuthentication adds: `hashed_password` attribute automatically
- Roles: owner, dispatcher, crew (enum)
- Policies: owner manages all, crew reads/updates self

### Schema Provisioning
- On company creation, run `CREATE SCHEMA tenant_{slug}`
- Then run tenant migrations into that schema
- AshPostgres provides `AshPostgres.MultiTenancy.migrate_tenant/2` or similar
- Alternatively, use Ecto SQL directly: `Ecto.Adapters.SQL.query!(Repo, "CREATE SCHEMA ...")`

### Policy Requirements
- Owner: full CRUD on all users in their tenant
- Crew: read own record, update own record (limited fields)
- Cross-tenant: User in tenant A cannot see tenant B's data (enforced by schema isolation)
- Unauthenticated: no access to `/app` routes

## Files That Will Be Created/Modified

### New Files
- `lib/haul/accounts.ex` — Ash.Domain for Accounts
- `lib/haul/accounts/company.ex` — Company resource
- `lib/haul/accounts/user.ex` — User resource with AshAuthentication
- `lib/haul/accounts/token.ex` — Token resource for auth
- `lib/haul/accounts/types/role.ex` — Custom Ash type or use Ash built-in enum
- `test/haul/accounts/` — Security + policy tests

### Modified Files
- `config/config.exs` — Add `:ash, :domains` config
- `lib/haul/repo.ex` — Add `installed_extensions` for AshPostgres
- `lib/haul_web/router.ex` — Add auth routes (sign-in, magic link)
- `lib/haul/application.ex` — Add AshAuthentication.Supervisor if needed

### Generated Files
- `priv/repo/migrations/*` — Via `mix ash_postgres.generate_migrations`
- `priv/repo/tenant_migrations/*` — For tenant-scoped tables

## Key Risks
- **AshAuthentication + multi-tenancy interaction** — User is tenant-scoped but auth tokens may need to work across the public schema. Token resource placement (public vs tenant) needs careful design.
- **Schema provisioning in tests** — Each test that creates a company needs a new schema, and SQL sandbox may complicate this.
- **Migration generation** — First time using `mix ash_postgres.generate_migrations` in this project; need to verify it works with the installed ash_postgres version.
