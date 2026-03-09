# T-004-01 Plan: Implementation Steps

## Step 1: Repo + Config Foundation
- Convert `Haul.Repo` to use `AshPostgres.Repo` (keeping Ecto.Repo compatibility)
- Add `installed_extensions: ["uuid-ossp", "citext"]`
- Add `config :ash, :domains, [Haul.Accounts]` to config.exs
- Verify: `mix compile` passes

## Step 2: Role Type + Token Resource
- Create `lib/haul/accounts/user/role.ex` — Ash.Type.Enum with [:owner, :dispatcher, :crew]
- Create `lib/haul/accounts/token.ex` — AshAuthentication.TokenResource with multitenancy :context
- Verify: modules compile

## Step 3: Company Resource
- Create `lib/haul/accounts/company.ex` with all attributes
- Create `lib/haul/accounts/changes/provision_tenant.ex` — schema provisioning change
- Actions: :create_company, :read, :update_company
- Identity on :slug
- Verify: module compiles

## Step 4: User Resource
- Create `lib/haul/accounts/user.ex` with AshAuthentication
- Password strategy + magic link strategy
- Multitenancy :context
- Policies: owner full access, crew self-only
- Verify: module compiles

## Step 5: Domain Module
- Create `lib/haul/accounts.ex` — Ash.Domain declaring all three resources
- Verify: `mix compile` clean

## Step 6: Generate & Run Migrations
- Run `mix ash_postgres.generate_migrations --name create_accounts`
- Review generated migrations
- Run `mix ash_postgres.migrate` for public schema
- Verify: migrations applied, tables exist

## Step 7: Router + Auth Integration
- Add AshAuthentication.Phoenix routes to router
- Add auth pipeline with session/authentication plugs
- Stub `/app` scope (empty, behind auth)
- Verify: `mix compile`, routes visible in `mix phx.routes`

## Step 8: Test Helpers
- Update `test/support/data_case.ex` with tenant creation/cleanup helpers
- Create factory or helper for creating companies + users in tests

## Step 9: Security Tests
- `test/haul/accounts/security_test.exs`:
  - Cross-tenant isolation (two companies, verify data separation)
  - Owner policy (can manage all users)
  - Crew policy (read/update self only)
  - Company creation provisions schema
  - Schema drop removes tenant data
- Verify: `mix test` all passing

## Step 10: Auth Flow Tests
- `test/haul/accounts/user_test.exs`:
  - Password registration creates user
  - Password sign-in returns user
  - Role defaults to :crew
- Verify: `mix test` all passing

## Verification Criteria
- `mix compile --warnings-as-errors` passes
- `mix test` passes (existing 12 + new security/auth tests)
- `mix format` clean
- Company creation provisions a Postgres schema
- Users in different tenant schemas are isolated
- Policy enforcement works for owner vs crew roles
