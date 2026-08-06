start = System.monotonic_time(:millisecond)
{:ok, company} = Haul.Accounts.Company |> Ash.Changeset.for_create(:create_company, %{name: "Benchmark Co #{System.unique_integer([:positive])}"}) |> Ash.create()
elapsed = System.monotonic_time(:millisecond) - start
IO.puts("ProvisionTenant (via create_company): #{elapsed}ms")

# Clean up
tenant = "tenant_#{company.slug}"
Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{tenant}\" CASCADE")
Ecto.Adapters.SQL.query!(Haul.Repo, "DELETE FROM companies WHERE id = $1::uuid", [Ecto.UUID.dump!(company.id)])
