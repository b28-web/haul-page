# T-004-01 Design: Company & User Resources

## Decision 1: Domain Structure

**Chosen:** Single `Haul.Accounts` domain containing Company, User, and Token resources.

Alternatives considered:
- Separate domains for Company (public) and User (tenant) — rejected because they're tightly coupled through auth and both belong to the Accounts bounded context.
- Flat resources without domain — rejected, Ash 3.x requires domains.

## Decision 2: Multi-Tenancy Architecture

**Chosen:** AshPostgres `:context` strategy with schema-per-tenant.

- Company lives in `public` schema (no multitenancy on Company itself)
- User and Token live in tenant schemas (e.g., `tenant_demo_hauling`)
- Tenant schema name derived from company slug: `"tenant_#{slug}"`
- Company creation triggers schema provisioning via an Ash change module

This matches the spec requirement. Row-level tenancy was rejected — schema isolation provides stronger guarantees and simpler security testing.

## Decision 3: Token Resource Placement

**Chosen:** Token resource in tenant schemas (same as User).

Rationale:
- Tokens belong to users, users are tenant-scoped
- Keeps auth tokens isolated per tenant
- AshAuthentication can find tokens when tenant context is set during auth flows
- For magic link flows, the email contains the token + tenant identifier, so we can set tenant context before token lookup

Rejected: Public schema tokens — would break tenant isolation principle.

## Decision 4: Authentication Strategies

**Chosen:** Password (bcrypt) + Magic Link, both via AshAuthentication.

Password strategy:
- `identity_field: :email`, `hashed_password_field: :hashed_password`
- Registration action: `:register_with_password`
- Sign-in action: `:sign_in_with_password`
- Uses bcrypt_elixir (already installed)

Magic link strategy:
- Sends token via email to `Haul.Mailer`
- Token stored in Token resource
- Sign-in action: `:sign_in_with_magic_link`
- Request action: `:request_magic_link`

Token generation:
- AshAuthentication token generation enabled
- Token resource: `Haul.Accounts.Token`
- Signing secret from application config (endpoint secret reused initially)

## Decision 5: Role System

**Chosen:** Ash enum type `:role` with values `[:owner, :dispatcher, :crew]`.

- Defined as `Ash.Type.Enum` in `Haul.Accounts.User.Role`
- Default role: `:crew`
- Owner is set during company creation (first user)
- Dispatcher is an intermediate role for future booking management

Rejected: Separate roles/permissions table — overkill for 3 fixed roles.

## Decision 6: Policy Design

**Chosen:** Ash.Policy on User resource with actor-based checks.

```
- Owner of same tenant: full CRUD on all users
- Dispatcher: read all users, update self
- Crew: read self, update self (name, phone only)
- No actor (unauthenticated): deny all
```

Cross-tenant isolation is handled by schema separation — policies only govern within-tenant access. Company resource policies: only the platform (no actor checks for now, seed-only creation).

## Decision 7: Schema Provisioning

**Chosen:** Custom Ash change module `Haul.Accounts.Changes.ProvisionTenant`.

- Runs after Company creation
- Executes `CREATE SCHEMA IF NOT EXISTS tenant_{slug}`
- Runs `AshPostgres.MultiTenancy.migrate_tenant(Haul.Repo, "tenant_{slug}")`
- Wrapped in the same transaction as company creation where possible

Rejected: External GenServer/Oban job — too complex for synchronous provisioning needs. Schema creation is fast and should happen inline.

## Decision 8: Company Creation Action

**Chosen:** Named action `:create_company` (not `:create`).

- Accepts: name, slug (optional, derived from name), timezone (default UTC), subscription_plan (default :free)
- Generates slug from name if not provided (downcased, hyphenated)
- Runs ProvisionTenant change after creation
- Creates first user (owner) as a separate step (not in the same action)

## Decision 9: Router Integration (Minimal)

**Chosen:** Add AshAuthentication routes but NOT full `/app` scope yet.

This ticket establishes the resources, policies, and tests. Full route protection (unauthenticated → redirect) is verified in tests but the `/app` scope is a stub — downstream tickets build the actual operator UI.

Auth routes added:
- `POST /auth/sign-in` — password sign-in
- `POST /auth/register` — registration
- `GET /auth/magic-link/:token` — magic link callback
- `DELETE /auth/sign-out` — sign out

## Decision 10: Test Strategy

Security tests run in `mix test` (not a separate suite):

1. **Tenant isolation** — Create two companies (two schemas), create users in each, verify user in tenant A cannot query tenant B's users
2. **Role policies** — Owner can list/update all users; crew can only read/update self
3. **Schema provisioning** — Company creation produces a working schema; test by creating a user in it
4. **Auth flows** — Password registration and sign-in produce valid sessions
5. **Cleanup** — Test helper drops tenant schemas after each test to avoid schema accumulation
