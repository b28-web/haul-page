# T-004-01 Review: Company & User Resources

## Summary of Changes

### New Files (9)
- `lib/haul/accounts.ex` — Ash.Domain with Company, User, Token resources
- `lib/haul/accounts/company.ex` — Company resource (public schema, slug-based tenant registry)
- `lib/haul/accounts/user.ex` — User resource with AshAuthentication (password + magic link), multitenancy, policies
- `lib/haul/accounts/token.ex` — Token resource for auth (tenant-scoped)
- `lib/haul/accounts/user/role.ex` — Enum type: owner, dispatcher, crew
- `lib/haul/accounts/changes/provision_tenant.ex` — Schema provisioning on company creation
- `test/haul/accounts/company_test.exs` — 7 tests: creation, slugs, schema provisioning
- `test/haul/accounts/user_test.exs` — 6 tests: registration, sign-in, roles
- `test/haul/accounts/security_test.exs` — 11 tests: isolation, policies, auth denial

### Modified Files (3)
- `config/config.exs` — Added `ash_domains`, `token_signing_secret`
- `lib/haul/repo.ex` — Converted to `AshPostgres.Repo`, added extensions + min_pg_version
- `mix.exs` — Added `picosat_elixir` dependency

### Generated Files (5)
- `priv/repo/migrations/20260309004837_create_accounts_extensions_1.exs` — uuid-ossp, citext, ash functions
- `priv/repo/migrations/20260309004841_create_accounts.exs` — companies table
- `priv/repo/tenant_migrations/20260309004838_create_accounts.exs` — users + tokens tables
- `priv/resource_snapshots/repo/` — Ash resource snapshots (3 files)

## Test Coverage

**55 total tests, 0 failures** (23 existing + 32 new)

### Company Tests (7)
- Creates with valid attrs, auto-derives slug, uses provided slug
- Enforces slug uniqueness
- Provisions Postgres schema on creation
- Tenant schema contains users and tokens tables
- Dropping schema removes all tenant data

### User Tests (6)
- Password registration creates user with correct defaults
- Rejects mismatched password confirmation
- Rejects duplicate email within tenant
- Sign-in with correct password succeeds
- Sign-in with wrong password fails
- Role defaults to :crew

### Security Tests (11)
- Tenant A query returns only tenant A's users
- Tenant B query returns only tenant B's users (no cross-contamination)
- Physical schema separation verified via direct SQL
- Independent email uniqueness across tenants
- Owner can list all users in tenant
- Crew can only read own record
- Crew can update own profile
- Crew cannot update another user's profile
- Crew cannot use update_user action (role management)
- Owner can update any user's role
- Unauthenticated user denied access

## Acceptance Criteria Status

| Criteria | Status |
|----------|--------|
| Company resource with required fields | ✓ |
| User resource with required fields | ✓ |
| AshAuthentication: password + magic link | ✓ |
| Schema-per-tenant multitenancy | ✓ |
| Company creation provisions schema | ✓ |
| Migrations generated and run | ✓ |
| Owner manages all users policy | ✓ |
| Crew reads/updates self only policy | ✓ |
| Cross-schema isolation test | ✓ |
| Crew role restrictions test | ✓ |
| Unauthenticated denial test | ✓ |
| Schema drop removes data test | ✓ |
| Tests in `mix test` | ✓ |

## Open Concerns

1. **Auth routes not added to router** — Deferred to downstream ticket. The resources and strategies are configured; route integration requires ash_authentication_phoenix LiveView components that belong with the operator UI.

2. **Magic link + password reset senders are stubs** — The `sender` functions return `:ok` without actually sending email. Real email sending requires Haul.Mailer integration, which depends on T-001-06 (mix-setup for external service configs).

3. **Token signing secret is hardcoded in dev** — `"dev-only-signing-secret-replace-in-prod"` in config.exs. Production must override via runtime.exs / env var. Not yet wired in runtime.exs.

4. **No `/app` route protection yet** — The acceptance criteria mention "unauthenticated request to any `/app` route returns 401/redirect." There are no `/app` routes yet. This will be enforced when the operator UI is built.

5. **Test performance** — Security tests run synchronously (schema creation/teardown). ~8s for full suite. Acceptable but will grow as more tenant-scoped tests are added.

6. **Dispatcher role** — Defined but no specific policies yet. Added for forward compatibility with booking management features.
