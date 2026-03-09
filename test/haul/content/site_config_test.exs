defmodule Haul.Content.SiteConfigTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.SiteConfig

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Content Test Co"})
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

  describe "create_default" do
    test "creates a site config with required fields", %{tenant: tenant} do
      assert {:ok, config} =
               SiteConfig
               |> Ash.Changeset.for_create(
                 :create_default,
                 %{business_name: "Test Hauling", phone: "(555) 000-0000"},
                 tenant: tenant
               )
               |> Ash.create()

      assert config.business_name == "Test Hauling"
      assert config.phone == "(555) 000-0000"
      assert config.coupon_text == "10% OFF"
      assert config.primary_color == "#0f0f0f"
    end

    test "requires business_name", %{tenant: tenant} do
      assert {:error, _} =
               SiteConfig
               |> Ash.Changeset.for_create(
                 :create_default,
                 %{phone: "(555) 000-0000"},
                 tenant: tenant
               )
               |> Ash.create()
    end

    test "requires phone", %{tenant: tenant} do
      assert {:error, _} =
               SiteConfig
               |> Ash.Changeset.for_create(
                 :create_default,
                 %{business_name: "Test"},
                 tenant: tenant
               )
               |> Ash.create()
    end
  end

  describe "edit" do
    test "updates fields on existing config", %{tenant: tenant} do
      {:ok, config} =
        SiteConfig
        |> Ash.Changeset.for_create(
          :create_default,
          %{business_name: "Original", phone: "(555) 000-0000"},
          tenant: tenant
        )
        |> Ash.create()

      assert {:ok, updated} =
               config
               |> Ash.Changeset.for_update(:edit, %{
                 business_name: "Updated Name",
                 tagline: "Best junk removal in town"
               })
               |> Ash.update()

      assert updated.business_name == "Updated Name"
      assert updated.tagline == "Best junk removal in town"
      assert updated.phone == "(555) 000-0000"
    end
  end

  describe "read" do
    test "reads config within tenant", %{tenant: tenant} do
      {:ok, _} =
        SiteConfig
        |> Ash.Changeset.for_create(
          :create_default,
          %{business_name: "Readable", phone: "(555) 111-1111"},
          tenant: tenant
        )
        |> Ash.create()

      assert {:ok, [config]} = Ash.read(SiteConfig, tenant: tenant)
      assert config.business_name == "Readable"
    end
  end
end
