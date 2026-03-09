defmodule Haul.Content.SeederTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.{Endorsement, GalleryItem, Page, Service, SiteConfig}
  alias Haul.Content.Seeder

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Seed Test Co"})
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

  describe "seed!/1" do
    test "creates all content resources from seed files", %{tenant: tenant} do
      summary = Seeder.seed!(tenant)

      assert summary.site_config == :created
      assert length(summary.services) == 6
      assert length(summary.gallery_items) == 3
      assert length(summary.endorsements) == 4
      assert length(summary.pages) == 2

      # Verify records in DB
      assert [config] = Ash.read!(SiteConfig, tenant: tenant)
      assert config.business_name == "Junk & Handy"
      assert config.phone == "(555) 123-4567"

      services = Ash.read!(Service, tenant: tenant)
      assert length(services) == 6
      titles = Enum.map(services, & &1.title)
      assert "Junk Removal" in titles
      assert "Estate Cleanout" in titles

      gallery = Ash.read!(GalleryItem, tenant: tenant)
      assert length(gallery) == 3

      endorsements = Ash.read!(Endorsement, tenant: tenant)
      assert length(endorsements) == 4
      jane = Enum.find(endorsements, &(&1.customer_name == "Jane D."))
      assert jane.star_rating == 5
      assert jane.featured == true

      pages = Ash.read!(Page, tenant: tenant)
      assert length(pages) == 2
      about = Enum.find(pages, &(&1.slug == "about"))
      assert about.title == "About Us"
      assert about.body_html =~ "<h1>"
      assert about.body_html =~ "Junk &amp; Handy"
    end

    test "is idempotent — running twice produces same record counts", %{tenant: tenant} do
      Seeder.seed!(tenant)
      summary = Seeder.seed!(tenant)

      # Second run should update, not create duplicates
      assert summary.site_config == :updated
      assert Enum.all?(summary.services, &(&1 == :updated))
      assert Enum.all?(summary.gallery_items, &(&1 == :updated))
      assert Enum.all?(summary.endorsements, &(&1 == :updated))
      assert Enum.all?(summary.pages, &(&1 == :updated))

      # Record counts unchanged
      assert length(Ash.read!(Service, tenant: tenant)) == 6
      assert length(Ash.read!(GalleryItem, tenant: tenant)) == 3
      assert length(Ash.read!(Endorsement, tenant: tenant)) == 4
      assert length(Ash.read!(Page, tenant: tenant)) == 2
    end
  end

  describe "parse_frontmatter!/1" do
    test "splits YAML frontmatter from markdown body" do
      content = """
      ---
      slug: test
      title: Test Page
      ---

      # Hello

      Body content here.
      """

      {frontmatter, body} = Seeder.parse_frontmatter!(content)
      assert frontmatter["slug"] == "test"
      assert frontmatter["title"] == "Test Page"
      assert body =~ "# Hello"
      assert body =~ "Body content here."
    end

    test "raises on missing frontmatter" do
      assert_raise RuntimeError, ~r/Invalid frontmatter/, fn ->
        Seeder.parse_frontmatter!("no frontmatter here")
      end
    end
  end
end
