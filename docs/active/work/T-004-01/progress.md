# T-004-01 Progress

## Completed Steps

### Step 1: Repo + Config Foundation ✓
- Converted `Haul.Repo` to `AshPostgres.Repo` with installed_extensions and min_pg_version
- Added `ash_domains: [Haul.Accounts]` to config.exs
- Added token_signing_secret to config
- Added `picosat_elixir` dependency (required by Ash policy SAT solver)

### Step 2: Role Type + Token Resource ✓
- Created `Haul.Accounts.User.Role` enum: [:owner, :dispatcher, :crew]
- Created `Haul.Accounts.Token` with multitenancy :context

### Step 3: Company Resource ✓
- Created `Haul.Accounts.Company` in public schema
- Created `Haul.Accounts.Changes.ProvisionTenant` — creates schema + runs tenant migrations
- Slug auto-derived from name, uniqueness enforced

### Step 4: User Resource ✓
- Created `Haul.Accounts.User` with AshAuthentication
- Password + magic link strategies
- Multitenancy :context, policies for owner/crew access
- `require_token_presence_for_authentication?` set to true
- `require_interaction?` set on magic link

### Step 5: Domain Module ✓
- Created `Haul.Accounts` domain with Company, User, Token resources

### Step 6: Generate & Run Migrations ✓
- Extensions migration (uuid-ossp, citext, ash-functions)
- Public migration (companies table)
- Tenant migration (users + tokens tables)
- Both dev and test databases migrated

### Step 7: Router Integration
- Skipped — auth routes are better added with ash_authentication_phoenix LiveView integration in a downstream ticket

### Step 8-10: Tests ✓
- 7 company tests (creation, slug derivation, uniqueness, schema provisioning, table verification, schema drop)
- 6 user tests (registration, sign-in, password rejection, email uniqueness, role defaults)
- 11 security tests (cross-tenant isolation, schema separation, role policies, unauthenticated denial)
- All 55 tests passing (23 existing + 32 new)

## Deviations from Plan

1. **Router integration deferred** — Auth routes need ash_authentication_phoenix LiveView components which are better set up as part of the operator UI ticket, not the resource definition ticket.
2. **Policy bypasses for sign-in actions** — Added explicit bypasses for `:sign_in_with_password` and `:sign_in_with_magic_link` since these run without an actor.
3. **Cross-tenant test adjusted** — Schema-per-tenant isolation means the tenant context determines which schema to query. Tests verify physical schema separation rather than policy-based cross-tenant denial.
4. **picosat_elixir added** — Required by Ash's policy SAT solver, not in original deps.
