defmodule Haul.Test.SharedTenant do
  @moduledoc """
  Provisions a single shared tenant for test files that need an authenticated
  owner context but don't require tenant isolation. Created once in test_helper.exs,
  cleaned up via ExUnit.after_suite/1.

  Test files opt in by calling `shared_test_tenant()` (imported from ConnCase)
  in their setup_all block.
  """

  @app_key :shared_test_tenant

  @doc """
  Provisions the shared tenant (company + schema + owner + JWT).
  Cleans up any stale state first. Idempotent.
  """
  def provision! do
    if Application.get_env(:haul, @app_key) do
      :already_provisioned
    else
      cleanup_stale!()

      Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

      ctx =
        Haul.Test.Factories.build_authenticated_context(%{
          company_name: "Shared Test Co"
        })

      Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)

      Application.put_env(:haul, @app_key, ctx)
      :ok
    end
  end

  @doc """
  Returns the shared tenant context. Raises if not provisioned.
  """
  def get! do
    case Application.get_env(:haul, @app_key) do
      nil ->
        raise "Shared test tenant not provisioned. Ensure test_helper.exs calls SharedTenant.provision!()"

      ctx ->
        ctx
    end
  end

  @doc """
  Drops the shared tenant schema and company record.
  """
  def cleanup! do
    case Application.get_env(:haul, @app_key) do
      nil ->
        :ok

      ctx ->
        Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

        Ecto.Adapters.SQL.query(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{ctx.tenant}\" CASCADE")

        Ecto.Adapters.SQL.query(Haul.Repo, "DELETE FROM companies WHERE slug = $1", [
          ctx.company.slug
        ])

        Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)
        Application.delete_env(:haul, @app_key)
        :ok
    end
  end

  defp cleanup_stale! do
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

    Ecto.Adapters.SQL.query(Haul.Repo, "DELETE FROM companies WHERE name = $1", [
      "Shared Test Co"
    ])

    # Drop the schema if it exists from a prior crashed run
    {:ok, result} =
      Ecto.Adapters.SQL.query(Haul.Repo, """
      SELECT schema_name FROM information_schema.schemata
      WHERE schema_name = 'tenant_shared-test-co'
      """)

    for [schema] <- result.rows do
      Ecto.Adapters.SQL.query(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{schema}\" CASCADE")
    end

    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)
  end
end
