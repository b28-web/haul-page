defmodule Haul.Accounts.CompanyTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company

  setup do
    on_exit(fn ->
      # Clean up any tenant schemas created during tests
      {:ok, result} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- result.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    :ok
  end

  describe "create_company" do
    test "creates a company with valid attributes" do
      assert {:ok, company} =
               Company
               |> Ash.Changeset.for_create(:create_company, %{name: "Test Hauling"})
               |> Ash.create()

      assert company.name == "Test Hauling"
      assert company.slug == "test-hauling"
      assert company.timezone == "Etc/UTC"
      assert company.subscription_plan == :free
    end

    test "derives slug from name when not provided" do
      assert {:ok, company} =
               Company
               |> Ash.Changeset.for_create(:create_company, %{name: "Joe's Junk & Removal!"})
               |> Ash.create()

      assert company.slug == "joe-s-junk-removal"
    end

    test "uses provided slug when given" do
      assert {:ok, company} =
               Company
               |> Ash.Changeset.for_create(:create_company, %{
                 name: "Test Co",
                 slug: "custom-slug"
               })
               |> Ash.create()

      assert company.slug == "custom-slug"
    end

    test "enforces unique slug" do
      {:ok, _} =
        Company
        |> Ash.Changeset.for_create(:create_company, %{name: "Dupe", slug: "same-slug"})
        |> Ash.create()

      assert {:error, _} =
               Company
               |> Ash.Changeset.for_create(:create_company, %{name: "Dupe 2", slug: "same-slug"})
               |> Ash.create()
    end

    test "provisions a Postgres schema on creation" do
      {:ok, company} =
        Company
        |> Ash.Changeset.for_create(:create_company, %{name: "Schema Test Co"})
        |> Ash.create()

      schema_name = ProvisionTenant.tenant_schema(company.slug)

      {:ok, result} =
        Ecto.Adapters.SQL.query(
          Haul.Repo,
          """
          SELECT schema_name FROM information_schema.schemata
          WHERE schema_name = $1
          """,
          [schema_name]
        )

      assert length(result.rows) == 1
    end

    test "tenant schema contains users and tokens tables" do
      {:ok, company} =
        Company
        |> Ash.Changeset.for_create(:create_company, %{name: "Tables Test"})
        |> Ash.create()

      schema_name = ProvisionTenant.tenant_schema(company.slug)

      {:ok, result} =
        Ecto.Adapters.SQL.query(
          Haul.Repo,
          """
          SELECT table_name FROM information_schema.tables
          WHERE table_schema = $1
          ORDER BY table_name
          """,
          [schema_name]
        )

      table_names = Enum.map(result.rows, &hd/1)
      assert "users" in table_names
      assert "tokens" in table_names
    end

    test "dropping tenant schema removes all tenant data" do
      {:ok, company} =
        Company
        |> Ash.Changeset.for_create(:create_company, %{name: "Drop Test"})
        |> Ash.create()

      schema_name = ProvisionTenant.tenant_schema(company.slug)

      # Verify schema exists
      {:ok, result} =
        Ecto.Adapters.SQL.query(
          Haul.Repo,
          """
          SELECT schema_name FROM information_schema.schemata WHERE schema_name = $1
          """,
          [schema_name]
        )

      assert length(result.rows) == 1

      # Drop schema
      Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema_name}\" CASCADE")

      # Verify schema is gone
      {:ok, result} =
        Ecto.Adapters.SQL.query(
          Haul.Repo,
          """
          SELECT schema_name FROM information_schema.schemata WHERE schema_name = $1
          """,
          [schema_name]
        )

      assert result.rows == []
    end
  end
end
