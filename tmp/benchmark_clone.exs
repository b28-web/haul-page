# Benchmark: migration vs clone
alias Haul.Test.{Factories, SchemaTemplate}

# Ensure template is set up
SchemaTemplate.setup!()

# Benchmark migration path (3 runs)
migration_times =
  for _ <- 1..3 do
    start = System.monotonic_time(:millisecond)
    ctx = Factories.build_authenticated_context()
    elapsed = System.monotonic_time(:millisecond) - start

    # Clean up tenant schema + company
    Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{ctx.tenant}\" CASCADE")
    Ecto.Adapters.SQL.query!(Haul.Repo, "DELETE FROM companies WHERE slug = $1", [ctx.company.slug])

    elapsed
  end

IO.puts("Migration path: #{inspect(migration_times)} ms (avg #{Enum.sum(migration_times) / 3 |> round()}ms)")

# Benchmark clone path (3 runs)
clone_times =
  for _ <- 1..3 do
    start = System.monotonic_time(:millisecond)
    ctx = Factories.build_authenticated_context_fast()
    elapsed = System.monotonic_time(:millisecond) - start

    # Clean up tenant schema + company
    Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{ctx.tenant}\" CASCADE")
    Ecto.Adapters.SQL.query!(Haul.Repo, "DELETE FROM companies WHERE slug = $1", [ctx.company.slug])

    elapsed
  end

IO.puts("Clone path:     #{inspect(clone_times)} ms (avg #{Enum.sum(clone_times) / 3 |> round()}ms)")
IO.puts("Speedup:        #{(Enum.sum(migration_times) / Enum.sum(clone_times)) |> Float.round(1)}x")

# Verify structural equivalence
IO.puts("\n--- Structural equivalence check ---")

ctx_m = Factories.build_authenticated_context()
ctx_c = Factories.build_authenticated_context_fast()

{:ok, result_m} = Ecto.Adapters.SQL.query(Haul.Repo, """
  SELECT table_name, column_name, data_type, column_default, is_nullable
  FROM information_schema.columns
  WHERE table_schema = $1
  ORDER BY table_name, ordinal_position
""", [ctx_m.tenant])

{:ok, result_c} = Ecto.Adapters.SQL.query(Haul.Repo, """
  SELECT table_name, column_name, data_type, column_default, is_nullable
  FROM information_schema.columns
  WHERE table_schema = $1
  ORDER BY table_name, ordinal_position
""", [ctx_c.tenant])

# Normalize defaults (they contain schema name references)
normalize = fn rows, schema ->
  Enum.map(rows, fn [table, col, type, default, nullable] ->
    default = if is_binary(default), do: String.replace(default, schema, "__SCHEMA__"), else: default
    [table, col, type, default, nullable]
  end)
end

m_normalized = normalize.(result_m.rows, ctx_m.tenant)
c_normalized = normalize.(result_c.rows, ctx_c.tenant)

if m_normalized == c_normalized do
  IO.puts("PASS: Schemas are structurally identical (#{length(m_normalized)} columns)")
else
  IO.puts("FAIL: Schemas differ!")
  m_set = MapSet.new(m_normalized)
  c_set = MapSet.new(c_normalized)
  only_in_migration = MapSet.difference(m_set, c_set) |> MapSet.to_list()
  only_in_clone = MapSet.difference(c_set, m_set) |> MapSet.to_list()
  if only_in_migration != [], do: IO.puts("In migration only: #{inspect(only_in_migration)}")
  if only_in_clone != [], do: IO.puts("In clone only: #{inspect(only_in_clone)}")
end

# Clean up
Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{ctx_m.tenant}\" CASCADE")
Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{ctx_c.tenant}\" CASCADE")
Ecto.Adapters.SQL.query!(Haul.Repo, "DELETE FROM companies WHERE slug = $1", [ctx_m.company.slug])
Ecto.Adapters.SQL.query!(Haul.Repo, "DELETE FROM companies WHERE slug = $1", [ctx_c.company.slug])

SchemaTemplate.teardown!()
