# T-004-01 Structure: File-Level Blueprint

## New Files

### Domain
**`lib/haul/accounts.ex`** — Ash.Domain
- `use Ash.Domain`
- Declares resources: Company, User, Token
- Authorization default: `:when_requested`

### Resources

**`lib/haul/accounts/company.ex`** — Ash.Resource (public schema)
- `use Ash.Resource, domain: Haul.Accounts, data_layer: AshPostgres.DataLayer`
- No multitenancy (this IS the tenant root)
- Table: `companies`
- Attributes: id (uuid, primary_key), slug (string, unique), name (string), timezone (string, default "Etc/UTC"), subscription_plan (atom enum :free/:pro), stripe_customer_id (string, allow_nil)
- Identity: unique on :slug
- Actions: `:create_company` (create), `:read` (read), `:update_company` (update)
- Changes: `ProvisionTenant` on `:create_company` after action
- No policies for now (seed/admin only creation)

**`lib/haul/accounts/user.ex`** — Ash.Resource + AshAuthentication
- `use Ash.Resource, domain: Haul.Accounts, data_layer: AshPostgres.DataLayer`
- `use AshAuthentication`
- Multitenancy: `strategy: :context`
- Table: `users`
- Attributes: id (uuid), email (ci_string), name (string), role (Role enum, default :crew), phone (string, allow_nil), active (boolean, default true)
- AshAuthentication adds hashed_password automatically
- Strategies: password (bcrypt), magic_link
- Token generation: enabled, token_resource: Haul.Accounts.Token
- Policies:
  - `authorize_if actor.role == :owner` for all actions
  - `authorize_if relating_to_actor` for read/update (crew reads/updates self)
  - `forbid` default

**`lib/haul/accounts/token.ex`** — Ash.Resource + AshAuthentication.TokenResource
- `use Ash.Resource, domain: Haul.Accounts, data_layer: AshPostgres.DataLayer`
- `use AshAuthentication.TokenResource`
- Multitenancy: `strategy: :context`
- Table: `tokens`

**`lib/haul/accounts/user/role.ex`** — Ash.Type.Enum
- Values: `[:owner, :dispatcher, :crew]`

### Changes

**`lib/haul/accounts/changes/provision_tenant.ex`** — Custom Ash change
- `use Ash.Resource.Change`
- After create: derives schema name from slug, creates Postgres schema, runs tenant migrations

### Checks

**`lib/haul/accounts/checks/role.ex`** — Custom Ash policy check
- Checks if actor has a specific role (parameterized)

## Modified Files

**`config/config.exs`**
- Add: `config :ash, :domains, [Haul.Accounts]`
- Add: `config :haul, :ash_authentication, signing_secret: "..."` (or reference endpoint secret)

**`lib/haul/repo.ex`**
- Add: `use AshPostgres.Repo, otp_app: :haul` (replaces or supplements Ecto.Repo)
- Add: `installed_extensions: ["uuid-ossp", "citext"]`
- Add: `min_pg_version: "16.0"`

**`lib/haul/application.ex`**
- Add `AshAuthentication.Supervisor` to children (if required by v4.13)

**`lib/haul_web/router.ex`**
- Add auth routes via `AshAuthentication.Phoenix.Router` macros
- Add `:auth` pipeline with session fetch + AshAuthentication plugs
- Stub `/app` scope behind auth (empty for now)

**`test/support/data_case.ex`**
- Add tenant helper: `create_tenant/1` that creates a company + provisions schema
- Add cleanup: `drop_tenant_schema/1` in `on_exit`

## Generated Files (via mix tasks)

**`priv/repo/migrations/TIMESTAMP_create_companies.exs`**
- Creates `companies` table in public schema

**`priv/repo/tenant_migrations/TIMESTAMP_create_users.exs`**
- Creates `users` table (runs per-tenant schema)

**`priv/repo/tenant_migrations/TIMESTAMP_create_tokens.exs`**
- Creates `tokens` table (runs per-tenant schema)

## Test Files

**`test/haul/accounts/company_test.exs`**
- Company creation provisions a schema
- Slug uniqueness enforced
- Schema exists in pg after creation

**`test/haul/accounts/user_test.exs`**
- Registration via password strategy
- Sign-in via password
- Role defaults to :crew

**`test/haul/accounts/security_test.exs`**
- Cross-tenant isolation: user in tenant A cannot read tenant B
- Owner can list all users in tenant
- Crew can only read self
- Crew cannot access financial fields (stripe_customer_id on Company — but Company isn't tenant-scoped, so this may be a policy on Company read)
- Unauthenticated access denied

## Module Dependency Order

1. `Haul.Accounts.User.Role` (type, no deps)
2. `Haul.Accounts.Token` (resource, no deps on User)
3. `Haul.Accounts.Changes.ProvisionTenant` (change module, needs Repo)
4. `Haul.Accounts.Company` (resource, uses ProvisionTenant)
5. `Haul.Accounts.User` (resource, uses Role, references Token)
6. `Haul.Accounts` (domain, references all resources)
7. Config updates (references domain)
8. Router updates (references auth)
