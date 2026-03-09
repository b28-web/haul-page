defmodule Haul.Operations.JobTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Operations.Job

  @valid_attrs %{
    customer_name: "Jane Doe",
    customer_phone: "(555) 987-6543",
    customer_email: "jane@example.com",
    address: "123 Main St, Anytown, USA",
    item_description: "Old couch and two mattresses",
    preferred_dates: [~D[2026-03-15], ~D[2026-03-16]]
  }

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Test Hauling"})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    on_exit(fn ->
      {:ok, result} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- result.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    %{tenant: tenant}
  end

  describe "create_from_online_booking" do
    test "creates a job in :lead state", %{tenant: tenant} do
      assert {:ok, job} =
               Job
               |> Ash.Changeset.for_create(:create_from_online_booking, @valid_attrs,
                 tenant: tenant
               )
               |> Ash.create()

      assert job.state == :lead
      assert job.customer_name == "Jane Doe"
      assert job.customer_phone == "(555) 987-6543"
      assert job.customer_email == "jane@example.com"
      assert job.address == "123 Main St, Anytown, USA"
      assert job.item_description == "Old couch and two mattresses"
      assert job.preferred_dates == [~D[2026-03-15], ~D[2026-03-16]]
    end

    test "requires customer_name", %{tenant: tenant} do
      attrs = Map.delete(@valid_attrs, :customer_name)

      assert {:error, _} =
               Job
               |> Ash.Changeset.for_create(:create_from_online_booking, attrs, tenant: tenant)
               |> Ash.create()
    end

    test "requires customer_phone", %{tenant: tenant} do
      attrs = Map.delete(@valid_attrs, :customer_phone)

      assert {:error, _} =
               Job
               |> Ash.Changeset.for_create(:create_from_online_booking, attrs, tenant: tenant)
               |> Ash.create()
    end

    test "requires address", %{tenant: tenant} do
      attrs = Map.delete(@valid_attrs, :address)

      assert {:error, _} =
               Job
               |> Ash.Changeset.for_create(:create_from_online_booking, attrs, tenant: tenant)
               |> Ash.create()
    end

    test "requires item_description", %{tenant: tenant} do
      attrs = Map.delete(@valid_attrs, :item_description)

      assert {:error, _} =
               Job
               |> Ash.Changeset.for_create(:create_from_online_booking, attrs, tenant: tenant)
               |> Ash.create()
    end

    test "customer_email is optional", %{tenant: tenant} do
      attrs = Map.delete(@valid_attrs, :customer_email)

      assert {:ok, job} =
               Job
               |> Ash.Changeset.for_create(:create_from_online_booking, attrs, tenant: tenant)
               |> Ash.create()

      assert is_nil(job.customer_email)
    end

    test "notes is optional", %{tenant: tenant} do
      attrs = Map.put(@valid_attrs, :notes, "Please call before arriving")

      assert {:ok, job} =
               Job
               |> Ash.Changeset.for_create(:create_from_online_booking, attrs, tenant: tenant)
               |> Ash.create()

      assert job.notes == "Please call before arriving"
    end

    test "preferred_dates defaults to empty list", %{tenant: tenant} do
      attrs = Map.delete(@valid_attrs, :preferred_dates)

      assert {:ok, job} =
               Job
               |> Ash.Changeset.for_create(:create_from_online_booking, attrs, tenant: tenant)
               |> Ash.create()

      assert job.preferred_dates == []
    end
  end
end
