defmodule Haul.Test.TenantPool do
  @moduledoc """
  Provisions a pool of tenant schemas at suite start for use with ExUnit
  concurrency groups. Each group gets its own pre-provisioned tenant so
  tests within a group can share a tenant while running in parallel with
  other groups.

  ## Usage

      # In test_helper.exs
      Haul.Test.TenantPool.provision!(count: 3)
      ExUnit.after_suite(fn _ -> Haul.Test.TenantPool.teardown!() end)

      # In test files
      use HaulWeb.ConnCase, async: {:group, :pool_a}
      # Test context automatically includes %{company, tenant, user, token}
  """

  @pool_key :haul_test_tenant_pool
  @group_names ~w(pool_a pool_b pool_c)a

  @doc """
  Provisions `count` tenant schemas using SchemaTemplate.clone!/1.
  Stores contexts in :persistent_term for fast, process-safe reads.

  Must be called before `Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)`.
  """
  def provision!(opts \\ []) do
    count = Keyword.get(opts, :count, 3)
    names = Enum.take(@group_names, count)

    # Need auto mode for DDL (schema creation)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

    # Drop stale pool schemas from previous runs
    for name <- names do
      tenant = "tenant___#{name}__"
      Ecto.Adapters.SQL.query(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{tenant}\" CASCADE")
    end

    Ecto.Adapters.SQL.query(Haul.Repo, "DELETE FROM companies WHERE slug LIKE '__pool_%'")

    pool =
      names
      |> Enum.map(fn name ->
        slug = "__#{name}__"

        # Create company without triggering tenant provisioning
        Application.put_env(:haul, :skip_tenant_provision, true)
        company = Haul.Test.Factories.build_company(%{slug: slug, name: "Pool #{name}"})
        Application.delete_env(:haul, :skip_tenant_provision)

        # Clone template schema for fast provisioning
        tenant = Haul.Test.SchemaTemplate.clone!(slug)

        # Register a user in the tenant
        %{user: user, token: token} = Haul.Test.Factories.build_user(tenant)

        {name, %{company: company, tenant: tenant, user: user, token: token}}
      end)
      |> Map.new()

    # Restore manual mode
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)
    Ecto.Adapters.SQL.Sandbox.checkin(Haul.Repo)

    :persistent_term.put(@pool_key, pool)

    names
  end

  @doc """
  Returns the tenant context `%{company, tenant, user, token}` for a
  concurrency group. Raises if the group was not provisioned.
  """
  def checkout(group) when is_atom(group) do
    pool = :persistent_term.get(@pool_key, nil)

    unless pool do
      raise "TenantPool not provisioned — call TenantPool.provision!/1 in test_helper.exs"
    end

    case Map.fetch(pool, group) do
      {:ok, context} ->
        context

      :error ->
        raise "Unknown pool group #{inspect(group)}. Available: #{inspect(Map.keys(pool))}"
    end
  end

  @doc """
  Returns the list of available group names.
  """
  def groups do
    pool = :persistent_term.get(@pool_key, %{})
    Map.keys(pool)
  end

  @doc """
  Drops all pool tenant schemas and removes the persistent_term entry.
  Call in ExUnit.after_suite/1.
  """
  def teardown! do
    pool = :persistent_term.get(@pool_key, %{})

    if map_size(pool) > 0 do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

      for {_group, %{tenant: tenant}} <- pool do
        Ecto.Adapters.SQL.query(Haul.Repo, "DROP SCHEMA IF EXISTS \"#{tenant}\" CASCADE")
      end

      # Also clean up pool companies
      Ecto.Adapters.SQL.query(Haul.Repo, "DELETE FROM companies WHERE slug LIKE '__pool_%'")

      Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)
      Ecto.Adapters.SQL.Sandbox.checkin(Haul.Repo)
    end

    :persistent_term.erase(@pool_key)
    :ok
  end
end
