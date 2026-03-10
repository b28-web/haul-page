defmodule Haul.Test.SchemaTemplate do
  @moduledoc """
  Creates a pre-migrated template tenant schema once per test suite.
  Provides `clone!/1` to stamp out new tenant schemas in ~5-15ms
  instead of running 9 migrations (~231ms).

  ## Usage

      # In test_helper.exs
      Haul.Test.SchemaTemplate.setup!()
      ExUnit.after_suite(fn _ -> Haul.Test.SchemaTemplate.teardown!() end)

      # In factories
      tenant = Haul.Test.SchemaTemplate.clone!("my-slug")
  """

  @template_schema "__test_template__"

  @clone_function_sql ~s"""
  CREATE OR REPLACE FUNCTION clone_tenant_schema(source TEXT, target TEXT)
  RETURNS void AS $body$
  DECLARE
    tbl RECORD;
    fk RECORD;
  BEGIN
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', target);

    FOR tbl IN
      SELECT table_name FROM information_schema.tables
      WHERE table_schema = source AND table_type = 'BASE TABLE'
      ORDER BY table_name
    LOOP
      EXECUTE format('CREATE TABLE %I.%I (LIKE %I.%I INCLUDING ALL)',
        target, tbl.table_name, source, tbl.table_name);
    END LOOP;

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
        AND tc.table_name != ccu.table_name
    LOOP
      BEGIN
        EXECUTE format(
          'ALTER TABLE %I.%I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %I.%I(%I)',
          target, fk.source_table, fk.constraint_name,
          fk.source_column,
          target, fk.target_table, fk.target_column
        );
      EXCEPTION WHEN duplicate_object THEN
        NULL;
      END;
    END LOOP;

    EXECUTE format(
      'INSERT INTO %I.schema_migrations SELECT * FROM %I.schema_migrations',
      target, source
    );
  END;
  $body$ LANGUAGE plpgsql;
  """

  @doc """
  Creates the template schema, runs migrations, and installs the clone function.
  Call once per test suite in test_helper.exs.
  """
  def setup! do
    repo = Haul.Repo

    # Use :auto mode for DDL operations (schema creation, migrations)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)
    Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)

    # Drop any stale template from a previous crashed run
    Ecto.Adapters.SQL.query!(repo, "DROP SCHEMA IF EXISTS \"#{@template_schema}\" CASCADE")

    # Create and migrate the template schema
    Ecto.Adapters.SQL.query!(repo, "CREATE SCHEMA \"#{@template_schema}\"")
    AshPostgres.MultiTenancy.migrate_tenant(@template_schema, repo)

    # Install the PL/pgSQL clone function
    Ecto.Adapters.SQL.query!(repo, @clone_function_sql)

    # Restore manual mode for normal test sandbox operation, then release connection
    Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)
    Ecto.Adapters.SQL.Sandbox.checkin(repo)

    :ok
  end

  @doc """
  Clones the template schema to `tenant_{slug}`. Returns the tenant string.
  Typically completes in 5-15ms vs ~231ms for full migration.
  """
  def clone!(slug) do
    tenant = "tenant_#{slug}"

    Ecto.Adapters.SQL.query!(
      Haul.Repo,
      "SELECT clone_tenant_schema($1, $2)",
      [@template_schema, tenant]
    )

    tenant
  end

  @doc """
  Drops the template schema and clone function. Call in ExUnit.after_suite/1.
  """
  def teardown! do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

    Ecto.Adapters.SQL.query(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{@template_schema}\" CASCADE")
    Ecto.Adapters.SQL.query(Haul.Repo, "DROP FUNCTION IF EXISTS clone_tenant_schema(TEXT, TEXT)")

    Ecto.Adapters.SQL.Sandbox.checkin(Haul.Repo)
    :ok
  end
end
