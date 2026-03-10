# T-035-01 Research: Schema Template Clone

## Current Provisioning Flow

`ProvisionTenant` (after_action hook on Company create):
1. `CREATE SCHEMA IF NOT EXISTS "tenant_{slug}"` (~1.5ms)
2. `AshPostgres.MultiTenancy.migrate_tenant(schema, Repo)` (~229ms)

Total: ~231ms per call. The migration framework overhead dominates — it discovers, loads, compiles, and executes 9 migration files sequentially.

## Tenant Schema Structure

9 migrations produce 12 tables + 1 index + several foreign keys:

| Table | Source Migration | Notes |
|-------|-----------------|-------|
| users | CreateAccounts | PK uuid, citext email, unique index |
| tokens | CreateAccounts | PK jti (text) |
| jobs | CreateOperations | PK uuid, text[] photo_urls, payment_intent_id |
| site_configs | CreateContent | PK uuid, many text columns |
| site_configs_versions | CreateContent | PK uuid, jsonb changes |
| services | CreateContent | PK uuid, category, active bool |
| services_versions | CreateContent | PK uuid, FK → services |
| pages | CreateContent | PK uuid, unique slug index |
| pages_versions | CreateContent | PK uuid, FK → pages |
| gallery_items | CreateContent | PK uuid, active bool |
| gallery_items_versions | CreateContent | PK uuid (FK removed) |
| endorsements | CreateContent | PK uuid, FK → jobs, sort_order |
| endorsements_versions | CreateContent | PK uuid |
| schema_migrations | auto-created | Ecto migration tracking |

**No custom PostgreSQL types**, enums, triggers, views, or functions exist in tenant schemas. All enums are stored as text columns. All IDs use `gen_random_uuid()`. This makes cloning straightforward.

## PostgreSQL Schema Cloning Approaches

### Option A: `CREATE TABLE ... LIKE ... INCLUDING ALL`
PostgreSQL's `LIKE` clause copies table structure including defaults, constraints, indexes, and sequences:
```sql
CREATE TABLE new_schema.tbl (LIKE template_schema.tbl INCLUDING ALL);
```
`INCLUDING ALL` = INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES INCLUDING STORAGE INCLUDING COMMENTS INCLUDING GENERATED INCLUDING STATISTICS.

This copies per-table, so we need to iterate all tables. Cross-table foreign keys need manual recreation since `LIKE` doesn't copy them.

### Option B: `pg_dump --schema-only | sed | psql`
Dump the template schema, replace schema name, replay DDL. Heavy — spawns external process, shell escaping, parsing.

### Option C: Direct SQL via `information_schema`
Query `information_schema.tables` and `information_schema.columns` to generate DDL dynamically. Most complex but most control.

**Option A is the best fit**: simple, handles our table-only schema, native PostgreSQL performance.

## Key Details

### Foreign keys in tenant schemas
- `services_versions → services.id` (version_source_id_fkey)
- `pages_versions → pages.id` (version_source_id_fkey)
- `endorsements → jobs.id` (endorsements_job_id_fkey)
- `endorsements_versions → endorsements.id` (version_source_id_fkey)
- `gallery_items_versions → gallery_items.id` was REMOVED in migration 20260309030223
- `site_configs_versions → site_configs.id` was REMOVED in migration 20260309030223

`LIKE INCLUDING ALL` will copy constraints on the source table but NOT cross-table FKs. Need to copy those separately.

Wait — actually, `INCLUDING ALL` includes `INCLUDING CONSTRAINTS` which copies CHECK constraints and NOT NULL, but does NOT copy FOREIGN KEY constraints (those are table-level, not column-level in the LIKE context). So we need to recreate FKs manually OR rely on the fact that `LIKE INCLUDING ALL` with a foreign key ON the table being copied... Actually, `INCLUDING CONSTRAINTS` does include foreign keys IF they reference the same table. Cross-table FKs need manual creation.

### schema_migrations table
The template schema will contain a `schema_migrations` table with records for all 9 migrations. When we clone, this table and its data should be copied so that `migrate_tenant` considers the tenant already migrated. But `LIKE` doesn't copy data — we'd need a separate `INSERT INTO ... SELECT FROM`.

Actually — if we're using `clone_tenant/1` as an alternative to `ProvisionTenant.tenant_schema/1`, we bypass `migrate_tenant` entirely. Tests that use `clone_tenant/1` don't need the schema_migrations table to be populated because they never call `migrate_tenant`. But it's safer to include it for correctness.

### Sequences
UUID primary keys use `gen_random_uuid()` defaults, not sequences. Only `sort_order` might use sequences (bigint). Let me check... No, `sort_order` has `default: 0` — it's a manual column. There are no sequences in the tenant schema. This simplifies cloning significantly.

## Test Integration Points

- `Haul.Test.Factories.build_authenticated_context/1` calls `build_company/1` which triggers `ProvisionTenant` via the `:create_company` Ash action
- We can't bypass the Ash action (it creates the company record). But we CAN modify `ProvisionTenant` to use cloning in test mode, or create a separate factory function.
- The ticket asks for `Factories.clone_tenant/1` — this would need to: (1) create the schema via clone, (2) return the tenant string. The company must already exist.
- Better: `build_company/1` currently triggers `ProvisionTenant` which runs migrations. We could make `build_company` use a separate code path in tests. But that's invasive.
- Simplest: Add `clone_tenant/1` to Factories. It creates the company WITHOUT the ProvisionTenant hook, then clones from the template. Tests switch from `build_authenticated_context()` to a variant that uses `clone_tenant/1`.

## Template Schema Lifecycle

Created once per `mix test` run in `test_helper.exs`:
1. Create a schema `__test_template__`
2. Run `AshPostgres.MultiTenancy.migrate_tenant("__test_template__", Repo)`
3. Install the `clone_tenant_schema` PL/pgSQL function
4. `ExUnit.after_suite/1` drops `__test_template__`

The PL/pgSQL function persists for the test session (in the database, not in memory).

## Benchmark Target

Current: ~231ms per provision
Target: ≤50ms per clone
Expected: ~5-15ms (CREATE SCHEMA + 12 × CREATE TABLE LIKE is simple DDL, no migration framework overhead)
