# T-026-01 Progress — native-postgres-switch

## Completed

### Step 1: Postgres installation approach
- **Attempted mise-managed Postgres** — failed. The `vfox-postgres` plugin builds from source and can't find `ossp-uuid` headers even with brew's `ossp-uuid` installed. The header detection issue is in the plugin's configure step, not our control.
- **Pivoted to Homebrew**: `brew install postgresql@18` installs the full server with all contrib extensions (uuid-ossp, citext, etc.)
- **Resolved brew keg-only issue**: `postgresql@18` is keg-only — needed `brew unlink libpq && brew link postgresql@18 --force` plus symlinks for share/lib paths that `pg_config --sharedir` expects.

### Step 2: Data directory initialization
- `initdb --locale=en_US.UTF-8 -E UTF-8 -U postgres --auth=trust /opt/homebrew/var/postgresql@18`
- Creates superuser `postgres` with trust auth (no password for local connections — matches dev/test config)

### Step 3: Postgres started, verified
- `pg_ctl start` succeeded
- `psql -U postgres -c 'SELECT version()'` confirms PostgreSQL 18.3 (Homebrew)

### Step 4: Database creation and migrations
- `mix ecto.create` — created `haul_dev` and `haul_test` databases
- `mix ecto.migrate` — all 12 migrations succeeded including:
  - `CREATE EXTENSION "uuid-ossp"` ✓
  - `CREATE EXTENSION "citext"` ✓
  - Ash custom functions (ash_elixir_or, ash_raise_error, etc.) ✓
  - uuid_generate_v7 ✓
  - Oban tables + triggers ✓
  - All DDL (companies, conversations, admin_users, ai_cost_entries) ✓

### Step 5: Test suite
- **845 tests, 1 failure** (stable across runs)
- The 1 failure is pre-existing: `signup_live_test.exs:51` — test bug where `create_authenticated_context()` creates company "Test Co 123" (slug "test-co-123") but test checks slug "test-co" (from name "Test Co") which is a different slug
- Tenant isolation tests: ✓
- Schema DDL (CREATE SCHEMA, SET search_path, DROP SCHEMA CASCADE): ✓
- All Ash extensions work on PG 18: ✓
- No PG 16→18 behavioral differences found

### Step 6: Justfile recipes
- Added `_pg`, `_pg-stop`, `_pg-status` recipes to `.just/system.just`
- Added `pg`, `pg-stop`, `pg-status` aliases to `justfile`
- Updated `_dev` to check `pg_isready` before starting
- Updated `_setup` to check `pg_isready` before DB setup

### Step 7: Documentation
- Updated `mise.toml` — added comment about Postgres via brew
- Updated `README.md` — quick start now includes `brew install postgresql@18` + `just pg`
- Updated `CONTRIBUTING.md` — setup section now includes Postgres steps
- Updated `_llm` recipe — stack description, dev server section, CI guardrails

### Deviation from plan
- **mise.toml does NOT pin Postgres** — the mise postgres plugin can't build with uuid-ossp support. Postgres is managed via Homebrew instead. The mise.toml comment documents this decision.
- **No new symlinks to `postgresql@18` directories needed** — handled via `brew link` during initial setup (one-time).
