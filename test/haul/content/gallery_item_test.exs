defmodule Haul.Content.GalleryItemTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.GalleryItem

  @valid_attrs %{
    before_image_url: "/images/before-1.jpg",
    after_image_url: "/images/after-1.jpg",
    caption: "Kitchen cleanout",
    alt_text: "Before and after kitchen cleanup"
  }

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Gallery Test Co #{System.unique_integer([:positive])}"
      })
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    on_exit(fn ->
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant}" CASCADE))
    end)

    %{tenant: tenant}
  end

  describe "add" do
    test "creates a gallery item with valid attributes", %{tenant: tenant} do
      assert {:ok, item} =
               GalleryItem
               |> Ash.Changeset.for_create(:add, @valid_attrs, tenant: tenant)
               |> Ash.create()

      assert item.before_image_url == "/images/before-1.jpg"
      assert item.after_image_url == "/images/after-1.jpg"
      assert item.caption == "Kitchen cleanout"
      assert item.featured == false
      assert item.active == true
      assert item.sort_order == 0
    end

    test "requires before_image_url and after_image_url", %{tenant: tenant} do
      assert {:error, _} =
               GalleryItem
               |> Ash.Changeset.for_create(:add, %{caption: "No images"}, tenant: tenant)
               |> Ash.create()
    end

    test "can set featured flag", %{tenant: tenant} do
      attrs = Map.put(@valid_attrs, :featured, true)

      assert {:ok, item} =
               GalleryItem
               |> Ash.Changeset.for_create(:add, attrs, tenant: tenant)
               |> Ash.create()

      assert item.featured == true
    end
  end

  describe "edit" do
    test "can update caption and featured status", %{tenant: tenant} do
      {:ok, item} =
        GalleryItem
        |> Ash.Changeset.for_create(:add, @valid_attrs, tenant: tenant)
        |> Ash.create()

      assert {:ok, updated} =
               item
               |> Ash.Changeset.for_update(:edit, %{caption: "Updated caption", featured: true})
               |> Ash.update()

      assert updated.caption == "Updated caption"
      assert updated.featured == true
    end
  end
end
