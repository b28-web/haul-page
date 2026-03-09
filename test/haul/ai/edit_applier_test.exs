defmodule Haul.AI.EditApplierTest do
  use Haul.DataCase, async: false

  alias Haul.AI.EditApplier
  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering
  alias Haul.Content.{Service, SiteConfig}

  @profile %OperatorProfile{
    business_name: "Edit Test Co",
    owner_name: "Test Owner",
    phone: "555-0000",
    email: "edit@example.com",
    service_area: "Test City",
    tagline: "We test it all!",
    years_in_business: 3,
    services: [
      %ServiceOffering{name: "Junk Removal", description: nil, category: :junk_removal},
      %ServiceOffering{name: "Yard Waste", description: nil, category: :yard_waste}
    ],
    differentiators: ["Fast", "Reliable"]
  }

  setup do
    # Provision a tenant with content
    {:ok, result} = Haul.Onboarding.run(%{name: "Edit Test Co", phone: "555-0000", email: "edit@example.com", area: "Test City"})

    on_exit(fn ->
      {:ok, res} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- res.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    %{tenant: result.tenant}
  end

  describe "apply_edit/3 direct updates" do
    test "updates phone number", %{tenant: tenant} do
      assert {:ok, msg} = EditApplier.apply_edit({:direct, :phone, "555-9999"}, tenant, @profile)
      assert msg =~ "phone"
      assert msg =~ "555-9999"

      [config] = Ash.read!(SiteConfig, tenant: tenant)
      assert config.phone == "555-9999"
    end

    test "updates email", %{tenant: tenant} do
      assert {:ok, msg} = EditApplier.apply_edit({:direct, :email, "new@example.com"}, tenant, @profile)
      assert msg =~ "email"

      [config] = Ash.read!(SiteConfig, tenant: tenant)
      assert config.email == "new@example.com"
    end

    test "updates business name", %{tenant: tenant} do
      assert {:ok, _} = EditApplier.apply_edit({:direct, :business_name, "New Name Co"}, tenant, @profile)

      [config] = Ash.read!(SiteConfig, tenant: tenant)
      assert config.business_name == "New Name Co"
    end

    test "updates service area", %{tenant: tenant} do
      assert {:ok, _} = EditApplier.apply_edit({:direct, :service_area, "New Area"}, tenant, @profile)

      [config] = Ash.read!(SiteConfig, tenant: tenant)
      assert config.service_area == "New Area"
    end

    test "updates owner name", %{tenant: tenant} do
      assert {:ok, _} = EditApplier.apply_edit({:direct, :owner_name, "Jane Doe"}, tenant, @profile)

      [config] = Ash.read!(SiteConfig, tenant: tenant)
      assert config.owner_name == "Jane Doe"
    end
  end

  describe "apply_edit/3 service management" do
    test "removes a service by name (soft delete)", %{tenant: tenant} do
      # First add a known service
      Service
      |> Ash.Changeset.for_create(:add, %{title: "Test Service", description: "Desc", icon: "fa-test"}, tenant: tenant)
      |> Ash.create!()

      assert {:ok, msg} = EditApplier.apply_edit({:remove_service, "Test Service"}, tenant, @profile)
      assert msg =~ "Removed"

      services = Ash.read!(Service, tenant: tenant)
      svc = Enum.find(services, &(&1.title == "Test Service"))
      assert svc.active == false
    end

    test "returns error for nonexistent service", %{tenant: tenant} do
      assert {:error, msg} = EditApplier.apply_edit({:remove_service, "Nonexistent"}, tenant, @profile)
      assert msg =~ "Could not find"
    end

    test "adds a new service", %{tenant: tenant} do
      assert {:ok, msg} = EditApplier.apply_edit({:add_service, "Demolition"}, tenant, @profile)
      assert msg =~ "Added"

      services = Ash.read!(Service, tenant: tenant)
      assert Enum.any?(services, &(&1.title == "Demolition"))
    end
  end

  describe "apply_edit/3 regeneration" do
    test "regenerates tagline", %{tenant: tenant} do
      assert {:ok, msg} = EditApplier.apply_edit({:regenerate, :tagline, "make it catchy"}, tenant, @profile)
      assert msg =~ "tagline"

      [config] = Ash.read!(SiteConfig, tenant: tenant)
      assert is_binary(config.tagline)
      assert String.length(config.tagline) > 0
    end

    test "regenerates service descriptions", %{tenant: tenant} do
      assert {:ok, msg} = EditApplier.apply_edit({:regenerate, :descriptions, "more professional"}, tenant, @profile)
      assert msg =~ "descriptions"
    end
  end

  describe "apply_edit/3 unknown" do
    test "returns help text for unknown edits", %{tenant: tenant} do
      assert {:error, msg} = EditApplier.apply_edit({:unknown, "I like blue"}, tenant, @profile)
      assert msg =~ "not sure what to change"
      assert msg =~ "Change phone"
    end
  end
end
