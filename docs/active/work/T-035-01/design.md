# T-035-01 Design: Schema Template Clone

## Decision: PL/pgSQL function using LIKE INCLUDING ALL + FK recreation

### Approach

1. **Template schema** — created once per `mix test` run via `test_helper.exs`. Full migration applied to `__test_template__` schema.

2. **PL/pgSQL clone function** — installed via raw SQL in `test_helper.exs`. Iterates `information_schema.tables` from template, creates each via `CREATE TABLE ... LIKE ... INCLUDING ALL`, then recreates cross-table foreign keys from `information_schema.table_constraints` + `information_schema.key_column_usage` + `information_schema.constraint_column_usage`.

3. **Elixir wrapper** — `Haul.Test.SchemaTemplate` module in `test/support/` handles template lifecycle. `clone!/1` creates a new schema from template. Used by factories as an alternative to `ProvisionTenant.tenant_schema/1`.

4. **Factory integration** — Modify `build_company/1` to skip `ProvisionTenant` when a flag is set, then clone manually. Or create a separate `build_company_with_clone/1`. The simplest approach: `build_authenticated_context/1` stays unchanged (still triggers ProvisionTenant), and we add a faster variant `build_authenticated_context_fast/1` that creates a company without provisioning, then clones the template.

Wait — `ProvisionTenant` is an `after_action` change on the `:create_company` action. We can't easily skip it without a separate Ash action. Better approach: create the company with a different action that doesn't trigger provisioning, then clone manually.

Actually, looking at the Company resource, there's only one create action (`:create_company`) and it always triggers `ProvisionTenant`. We'd need to either:
- Add a `:create_company_without_provision` action
- Or keep using `:create_company` but make ProvisionTenant check a flag

**Chosen approach:** Add a module attribute / application env flag that `ProvisionTenant` checks:
```elixir
# In ProvisionTenant
def change(changeset, _opts, _context) do
  if Application.get_env(:haul, :skip_tenant_provision) do
    changeset  # no-op
  else
    # normal provisioning
  end
end
```

Then in tests:
```elixir
def build_authenticated_context_fast(attrs \\ %{}) do
  Application.put_env(:haul, :skip_tenant_provision, true)
  company = build_company(attrs)
  Application.delete_env(:haul, :skip_tenant_provision)
  tenant = SchemaTemplate.clone!(company.slug)
  %{user: user, token: token} = build_user(tenant, attrs)
  %{company: company, tenant: tenant, user: user, token: token}
end
```

This is process-safe in sync tests (all current tests are sync). For async tests it would be unsafe, but `build_authenticated_context_fast` would only be used in sync tests anyway (it does DDL).

### Alternatives Rejected

**Option A: pg_dump/sed approach** — Rejected. Spawning external process is slow and fragile.

**Option B: Modify ProvisionTenant to always use clone in test** — Rejected. Would change production code paths based on test mode. The flag approach is simpler and the production code change is minimal (one guard clause).

**Option C: Direct information_schema DDL generation in Elixir** — Rejected. More complex than PL/pgSQL, and PL/pgSQL runs server-side (no round-trips per table).

### PL/pgSQL Function Design

```sql
CREATE OR REPLACE FUNCTION clone_tenant_schema(source TEXT, target TEXT)
RETURNS void AS $$
DECLARE
  tbl RECORD;
  fk RECORD;
BEGIN
  EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', target);

  -- Clone each table with structure, defaults, indexes, constraints
  FOR tbl IN
    SELECT table_name FROM information_schema.tables
    WHERE table_schema = source AND table_type = 'BASE TABLE'
    ORDER BY table_name
  DO
    EXECUTE format('CREATE TABLE %I.%I (LIKE %I.%I INCLUDING ALL)',
      target, tbl.table_name, source, tbl.table_name);
  END LOOP;

  -- Recreate cross-table foreign keys
  FOR fk IN
    SELECT
      tc.constraint_name,
      tc.table_name AS source_table,
      kcu.column_name AS source_column,
      ccu.table_name AS target_table,
      ccu.column_name AS target_column
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage ccu
      ON tc.constraint_name = ccu.constraint_name
      AND tc.table_schema = ccu.table_schema
    WHERE tc.table_schema = source
      AND tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_name != ccu.table_name  -- cross-table only
  DO
    EXECUTE format(
      'ALTER TABLE %I.%I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %I.%I(%I)',
      target, fk.source_table, fk.constraint_name,
      fk.source_column,
      target, fk.target_table, fk.target_column
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

Note: `LIKE INCLUDING ALL` already copies same-table constraints (CHECK, NOT NULL, defaults). Only cross-table FOREIGN KEYs need manual recreation.

### Schema Migrations Data

We DON'T need to copy `schema_migrations` data because:
- Tests using `clone_tenant/1` never call `migrate_tenant`
- The cloned schema has the correct table structure
- If someone accidentally calls `migrate_tenant` on a cloned schema, it would fail or be a no-op (tables exist)

Actually, it's safer to copy it so migrate_tenant is truly a no-op:
```sql
INSERT INTO target.schema_migrations SELECT * FROM source.schema_migrations;
```

This is a single fast query. Include it in the clone function.
