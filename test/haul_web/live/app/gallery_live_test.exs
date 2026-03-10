defmodule HaulWeb.App.GalleryLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Content.GalleryItem

  setup do
    auth = create_authenticated_context()
    on_exit(fn -> cleanup_tenant(auth.tenant) end)
    auth
  end

  defp create_item(tenant, attrs \\ %{}) do
    defaults = %{
      before_image_url: "/uploads/test/before.jpg",
      after_image_url: "/uploads/test/after.jpg",
      caption: "Test item",
      alt_text: "Before and after test"
    }

    GalleryItem
    |> Ash.Changeset.for_create(:add, Map.merge(defaults, attrs), tenant: tenant)
    |> Ash.create!()
  end

  describe "mount" do
    test "renders gallery page with empty state", %{conn: conn} = auth do
      {:ok, view, html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      assert html =~ "Gallery"
      assert html =~ "No gallery items yet"
      assert has_element?(view, "button", "Add Item")
    end

    test "renders existing gallery items", %{conn: conn, tenant: tenant} = auth do
      create_item(tenant, %{caption: "Kitchen cleanup"})
      create_item(tenant, %{caption: "Garage cleanout", sort_order: 1})

      {:ok, _view, html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      assert html =~ "Kitchen cleanup"
      assert html =~ "Garage cleanout"
      refute html =~ "No gallery items yet"
    end
  end

  describe "add item" do
    test "opens modal when add button clicked", %{conn: conn} = auth do
      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      html = view |> element("button", "Add Item") |> render_click()

      assert html =~ "Add Gallery Item"
      assert html =~ "Before Photo"
      assert html =~ "After Photo"
    end

    test "creates item with uploaded images", %{conn: conn, tenant: tenant} = auth do
      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      # Open modal
      view |> element("button", "Add Item") |> render_click()

      # Upload before image
      before_img =
        file_input(view, "form", :before_image, [
          %{
            name: "before.jpg",
            content: File.read!(Path.join([__DIR__, "../../../support/fixtures/test_image.jpg"])),
            type: "image/jpeg"
          }
        ])

      render_upload(before_img, "before.jpg")

      # Upload after image
      after_img =
        file_input(view, "form", :after_image, [
          %{
            name: "after.jpg",
            content: File.read!(Path.join([__DIR__, "../../../support/fixtures/test_image.jpg"])),
            type: "image/jpeg"
          }
        ])

      render_upload(after_img, "after.jpg")

      # Fill form and submit
      view
      |> form("form", gallery_item: %{caption: "New gallery item", alt_text: "Test alt"})
      |> render_submit()

      # Verify item was created
      assert {:ok, items} = Ash.read(GalleryItem, tenant: tenant)
      assert length(items) == 1
      assert hd(items).caption == "New gallery item"
    end
  end

  describe "edit item" do
    test "opens modal with existing data", %{conn: conn, tenant: tenant} = auth do
      item = create_item(tenant, %{caption: "Original caption"})

      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      html =
        view
        |> element(~s(button[phx-click="edit"][phx-value-id="#{item.id}"]))
        |> render_click()

      assert html =~ "Edit Gallery Item"
      assert html =~ "Original caption"
    end

    test "updates item metadata", %{conn: conn, tenant: tenant} = auth do
      item = create_item(tenant, %{caption: "Old caption"})

      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      view
      |> element(~s(button[phx-click="edit"][phx-value-id="#{item.id}"]))
      |> render_click()

      view
      |> form("form", gallery_item: %{caption: "Updated caption"})
      |> render_submit()

      {:ok, [updated]} = Ash.read(GalleryItem, tenant: tenant)
      assert updated.caption == "Updated caption"
    end
  end

  describe "delete item" do
    test "deletes item", %{conn: conn, tenant: tenant} = auth do
      item = create_item(tenant)

      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      view
      |> element(~s(button[phx-click="delete"][phx-value-id="#{item.id}"]))
      |> render_click()

      assert {:ok, []} = Ash.read(GalleryItem, tenant: tenant)
    end
  end

  describe "reorder" do
    test "moves item up", %{conn: conn, tenant: tenant} = auth do
      _first = create_item(tenant, %{caption: "First", sort_order: 0})
      second = create_item(tenant, %{caption: "Second", sort_order: 1})

      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      view
      |> element(~s(button[phx-click="move-up"][phx-value-id="#{second.id}"]))
      |> render_click()

      {:ok, items} = Ash.read(GalleryItem, tenant: tenant)
      reordered = Enum.sort_by(items, & &1.sort_order)
      assert hd(reordered).caption == "Second"
    end

    test "moves item down", %{conn: conn, tenant: tenant} = auth do
      first = create_item(tenant, %{caption: "First", sort_order: 0})
      _second = create_item(tenant, %{caption: "Second", sort_order: 1})

      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      view
      |> element(~s(button[phx-click="move-down"][phx-value-id="#{first.id}"]))
      |> render_click()

      {:ok, items} = Ash.read(GalleryItem, tenant: tenant)
      reordered = Enum.sort_by(items, & &1.sort_order)
      assert hd(reordered).caption == "Second"
    end
  end

  describe "toggle active" do
    test "deactivates and reactivates item", %{conn: conn, tenant: tenant} = auth do
      item = create_item(tenant)
      assert item.active == true

      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      # Deactivate
      view
      |> element(~s(button[phx-click="toggle-active"][phx-value-id="#{item.id}"]))
      |> render_click()

      {:ok, [toggled]} = Ash.read(GalleryItem, tenant: tenant)
      assert toggled.active == false

      # Reactivate
      view
      |> element(~s(button[phx-click="toggle-active"][phx-value-id="#{item.id}"]))
      |> render_click()

      {:ok, [reactivated]} = Ash.read(GalleryItem, tenant: tenant)
      assert reactivated.active == true
    end
  end

  describe "close modal" do
    test "closes modal on cancel", %{conn: conn} = auth do
      {:ok, view, _html} =
        conn
        |> log_in_user(auth)
        |> live(~p"/app/content/gallery")

      view |> element("button", "Add Item") |> render_click()
      assert render(view) =~ "Add Gallery Item"

      html = view |> element("button", "Cancel") |> render_click()
      refute html =~ "Add Gallery Item"
    end
  end
end
