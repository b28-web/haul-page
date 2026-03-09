defmodule Haul.Content.ServiceTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.Service

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Service Test Co"})
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

  describe "add" do
    test "creates a service with valid attributes", %{tenant: tenant} do
      assert {:ok, service} =
               Service
               |> Ash.Changeset.for_create(
                 :add,
                 %{title: "Junk Removal", description: "We haul it all", icon: "hero-truck"},
                 tenant: tenant
               )
               |> Ash.create()

      assert service.title == "Junk Removal"
      assert service.description == "We haul it all"
      assert service.icon == "hero-truck"
      assert service.sort_order == 0
      assert service.active == true
    end

    test "requires title, description, and icon", %{tenant: tenant} do
      assert {:error, _} =
               Service
               |> Ash.Changeset.for_create(:add, %{title: "Missing fields"}, tenant: tenant)
               |> Ash.create()
    end
  end

  describe "preparations" do
    test "services are sorted by sort_order", %{tenant: tenant} do
      for {title, order} <- [{"Third", 3}, {"First", 1}, {"Second", 2}] do
        Service
        |> Ash.Changeset.for_create(
          :add,
          %{title: title, description: "Desc", icon: "icon", sort_order: order},
          tenant: tenant
        )
        |> Ash.create!()
      end

      {:ok, services} = Ash.read(Service, tenant: tenant)
      titles = Enum.map(services, & &1.title)
      assert titles == ["First", "Second", "Third"]
    end
  end

  describe "edit" do
    test "can deactivate a service", %{tenant: tenant} do
      {:ok, service} =
        Service
        |> Ash.Changeset.for_create(
          :add,
          %{title: "Active", description: "Desc", icon: "icon"},
          tenant: tenant
        )
        |> Ash.create()

      assert {:ok, updated} =
               service
               |> Ash.Changeset.for_update(:edit, %{active: false})
               |> Ash.update()

      assert updated.active == false
    end
  end

  describe "destroy" do
    test "destroy is blocked by paper trail FK (versions reference source)", %{tenant: tenant} do
      {:ok, service} =
        Service
        |> Ash.Changeset.for_create(
          :add,
          %{title: "To Delete", description: "Desc", icon: "icon"},
          tenant: tenant
        )
        |> Ash.create()

      # Destroy fails because PaperTrail versions have a FK to the source record.
      # This is expected behavior — versions are the audit trail.
      assert {:error, _} = Ash.destroy(service)
    end
  end
end
