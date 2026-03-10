defmodule Haul.Content.PageTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.Page

  @valid_attrs %{
    slug: "about",
    title: "About Us",
    body: "# About\n\nWe haul junk.",
    meta_description: "Learn about our junk removal services"
  }

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Page Test Co #{System.unique_integer([:positive])}"
      })
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    on_exit(fn ->
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant}" CASCADE))
    end)

    %{tenant: tenant}
  end

  describe "draft" do
    test "creates a draft page with body_html populated", %{tenant: tenant} do
      assert {:ok, page} =
               Page
               |> Ash.Changeset.for_create(:draft, @valid_attrs, tenant: tenant)
               |> Ash.create()

      assert page.slug == "about"
      assert page.title == "About Us"
      assert page.body == "# About\n\nWe haul junk."
      assert page.body_html =~ "<h1>"
      assert page.body_html =~ "About"
      assert page.body_html =~ "<p>We haul junk.</p>"
      assert page.published == false
      assert is_nil(page.published_at)
    end

    test "requires slug, title, and body", %{tenant: tenant} do
      assert {:error, _} =
               Page
               |> Ash.Changeset.for_create(:draft, %{slug: "test"}, tenant: tenant)
               |> Ash.create()
    end

    test "enforces unique slug", %{tenant: tenant} do
      {:ok, _} =
        Page
        |> Ash.Changeset.for_create(:draft, @valid_attrs, tenant: tenant)
        |> Ash.create()

      assert {:error, _} =
               Page
               |> Ash.Changeset.for_create(
                 :draft,
                 Map.put(@valid_attrs, :title, "Different Title"),
                 tenant: tenant
               )
               |> Ash.create()
    end
  end

  describe "edit" do
    test "updates body and regenerates body_html", %{tenant: tenant} do
      {:ok, page} =
        Page
        |> Ash.Changeset.for_create(:draft, @valid_attrs, tenant: tenant)
        |> Ash.create()

      new_body = "# Updated\n\nNew content here."

      assert {:ok, updated} =
               page
               |> Ash.Changeset.for_update(:edit, %{body: new_body})
               |> Ash.update()

      assert updated.body == new_body
      assert updated.body_html =~ "<h1>"
      assert updated.body_html =~ "Updated"
      assert updated.body_html =~ "<p>New content here.</p>"
    end

    test "renders GFM tables in body_html", %{tenant: tenant} do
      table_body = """
      | Item | Price |
      |------|-------|
      | Sofa | $50   |
      """

      {:ok, page} =
        Page
        |> Ash.Changeset.for_create(
          :draft,
          Map.put(@valid_attrs, :body, table_body),
          tenant: tenant
        )
        |> Ash.create()

      assert page.body_html =~ "<table>"
      assert page.body_html =~ "<td>"
      assert page.body_html =~ "Sofa"
    end

    test "renders strikethrough in body_html", %{tenant: tenant} do
      {:ok, page} =
        Page
        |> Ash.Changeset.for_create(
          :draft,
          Map.put(@valid_attrs, :body, "~~removed~~"),
          tenant: tenant
        )
        |> Ash.create()

      assert page.body_html =~ "<del>"
      assert page.body_html =~ "removed"
    end
  end

  describe "publish/unpublish" do
    test "publish sets published to true and published_at", %{tenant: tenant} do
      {:ok, page} =
        Page
        |> Ash.Changeset.for_create(:draft, @valid_attrs, tenant: tenant)
        |> Ash.create()

      assert {:ok, published} =
               page
               |> Ash.Changeset.for_update(:publish, %{})
               |> Ash.update()

      assert published.published == true
      assert not is_nil(published.published_at)
    end

    test "unpublish sets published to false", %{tenant: tenant} do
      {:ok, page} =
        Page
        |> Ash.Changeset.for_create(:draft, @valid_attrs, tenant: tenant)
        |> Ash.create()

      {:ok, published} =
        page
        |> Ash.Changeset.for_update(:publish, %{})
        |> Ash.update()

      assert {:ok, unpublished} =
               published
               |> Ash.Changeset.for_update(:unpublish, %{})
               |> Ash.update()

      assert unpublished.published == false
    end
  end
end
