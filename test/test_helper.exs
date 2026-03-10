# Clean up stale data from previous runs (enables async: true by avoiding per-test global cleanup)
Haul.Test.Factories.cleanup_all_tenants()
Ecto.Adapters.SQL.query!(Haul.Repo, "DELETE FROM admin_users")
Ecto.Adapters.SQL.query!(Haul.Repo, "DELETE FROM companies")

# Pre-create the operator company + tenant + seed content once.
# Tests that need the operator tenant call Factories.operator_context() to look it up.
Haul.Test.Factories.ensure_operator_tenant!()

if System.get_env("HAUL_TEST_TIMING") == "1" do
  Application.put_env(:haul, :test_timing, %{
    compile_end: System.monotonic_time(:millisecond)
  })

  ExUnit.start(
    exclude: [:baml_live, :pool_infra],
    formatters: [ExUnit.CLIFormatter, Haul.Test.TimingFormatter]
  )
else
  ExUnit.start(exclude: [:baml_live, :pool_infra])
end

Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)

# Pre-migrate a template tenant schema for fast cloning (~5ms vs ~231ms per tenant)
Haul.Test.SchemaTemplate.setup!()

# Provision shared tenant pool for concurrency groups (3 tenants, ~15ms each via clone)
Haul.Test.TenantPool.provision!(count: 3)

ExUnit.after_suite(fn _ ->
  Haul.Test.TenantPool.teardown!()
  Haul.Test.SchemaTemplate.teardown!()
end)
