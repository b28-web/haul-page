# T-026-01 Plan — native-postgres-switch

## Step 1: Pin Postgres in mise.toml

**Change:** Add `postgres = "18"` to `[tools]` section, update comment.

**Verify:** `mise install` succeeds, `mise which pg_ctl` points to mise-managed binary.

## Step 2: Install Postgres via mise and initialize

**Action:** Run `mise install`, then `initdb` if no data dir exists, then `pg_ctl start`.

**Verify:** `pg_isready` succeeds, `psql -U postgres -c 'SELECT version()'` returns PG 18.

## Step 3: Add pg lifecycle recipes to system.just

**Changes to `.just/system.just`:**
- Add `_pg` recipe (idempotent start)
- Add `_pg-stop` recipe
- Add `_pg-status` recipe

**Verify:** `just pg` starts Postgres, `just pg-status` shows running, `just pg-stop` stops it.

## Step 4: Update _dev and _setup recipes

**Changes to `.just/system.just`:**
- `_dev`: Add `pg_isready` check before ecto commands. Print helpful message if down.
- `_setup`: Add `pg_isready` check after prerequisite check.

**Verify:** `just pg-stop && just dev` prints helpful message. `just pg && just dev` works.

## Step 5: Expose pg recipes in justfile

**Change:** Add `pg`, `pg-stop`, `pg-status` aliases pointing to private recipes.

**Verify:** `just --list` shows the new commands.

## Step 6: Create databases and run migrations

**Action:** `mix ecto.create` + `mix ecto.migrate` on native PG 18.

**Verify:** Databases exist, migrations complete without errors.

## Step 7: Run full test suite

**Action:** `mix test`

**Verify:** 845+ tests, 0 failures. Pay special attention to:
- `test/haul/tenant_isolation_test.exs` — schema-per-tenant DDL
- `test/haul/accounts/` — Company/User creation (triggers schema creation)
- `test/haul/content/` — content seeding across tenants
- Any Ash extension-dependent tests

## Step 8: Verify dev server

**Action:** `just dev`, verify Phoenix connects and serves pages.

**Verify:** `curl http://localhost:4000/` returns 200.

## Step 9: Update documentation

**Files:**
- `README.md` — update quick start and commands
- `CONTRIBUTING.md` — update setup instructions
- `.just/system.just` `_llm` recipe — update stack description

## Step 10: Document PG 16→18 differences

**Action:** Note any behavioral differences encountered during testing. If none, state that explicitly in the review.

## Testing Strategy

| What | How | When |
|------|-----|------|
| Postgres starts via mise | `just pg` + `pg_isready` | Step 2-3 |
| DB creation works | `mix ecto.create` | Step 6 |
| Migrations work | `mix ecto.migrate` | Step 6 |
| Tenant DDL works | `mix test test/haul/tenant_isolation_test.exs` | Step 7 |
| Full suite passes | `mix test` | Step 7 |
| Dev server works | `just dev` + `curl` | Step 8 |

## Commit Strategy

1. After Step 5: commit mise.toml + justfile + system.just changes
2. After Step 9: commit documentation updates
3. Or: single commit if all changes are small enough (likely)
