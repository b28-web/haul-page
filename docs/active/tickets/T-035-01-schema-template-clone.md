---
id: T-035-01
story: S-035
title: schema-template-clone
type: task
status: open
priority: high
phase: done
depends_on: []
---

## Context

`CREATE SCHEMA` + `AshPostgres.MultiTenancy.migrate_tenant/2` costs ~250ms per invocation. After S-034's `setup_all` work, most tests won't pay this cost — but tests that genuinely need per-test tenant isolation (security, tenant isolation, superadmin multi-company) still do. Those tests are the floor.

PostgreSQL has no native `CREATE SCHEMA FROM TEMPLATE`, but a PL/pgSQL function can clone a pre-migrated schema by copying table definitions, indexes, sequences, and constraints. This is faster than running migrations because it skips the migration framework overhead (loading migration files, checking migration version table, running each migration in sequence).

## Acceptance Criteria

- Create a PL/pgSQL function `clone_tenant_schema(source_schema, target_schema)` that:
  - Copies all tables (via `CREATE TABLE ... LIKE ... INCLUDING ALL`)
  - Copies sequences with correct ownership
  - Copies indexes and constraints
  - Does NOT copy data (tests start with empty tenant)
- Create a "template" tenant schema in `test_helper.exs` — run full migrations once, then clone from it
- Add `Haul.Test.Factories.clone_tenant/1` that uses the PL/pgSQL function instead of `ProvisionTenant`
- Measure: `clone_tenant/1` should complete in ≤50ms (down from ~250ms)
- Tests using `clone_tenant/1` pass identically to those using `build_authenticated_context/0`
- The clone function is test-only — not loaded in prod

## Implementation Notes

- Reference: https://wiki.postgresql.org/wiki/Clone_schema and https://github.com/denishpatel/pg-clone-schema
- The template schema should be created once per `mix test` run in `test_helper.exs`:
  ```elixir
  # In test_helper.exs
  Haul.Test.SchemaTemplate.create!()  # runs migrations on "__test_template__" schema
  ```
- Clone function in SQL:
  ```sql
  CREATE OR REPLACE FUNCTION clone_tenant_schema(source TEXT, target TEXT)
  RETURNS void AS $$
  BEGIN
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', target);
    -- iterate information_schema.tables, create each via LIKE INCLUDING ALL
    -- fix sequence defaults
  END;
  $$ LANGUAGE plpgsql;
  ```
- Install the function via a test-only migration or directly in `test_helper.exs` via raw SQL
- Watch for: sequence default references to old schema, enum types shared across schemas, custom types
- This project uses AshPostgres tenant migrations — verify the clone produces identical structure to `migrate_tenant/2`

## Risks

- Schema cloning edge cases: if tenant migrations create anything beyond tables/indexes/sequences (triggers, views, custom types), the clone function needs to handle those
- If AshPostgres changes its migration structure in a future version, the clone function may need updating
- Benchmark carefully — if the clone is only marginally faster than migrate_tenant, it's not worth the complexity
