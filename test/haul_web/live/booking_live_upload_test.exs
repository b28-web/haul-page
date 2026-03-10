defmodule HaulWeb.BookingLiveUploadTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    %{tenant: tenant, operator: operator} = create_operator_context()
    %{operator: operator, tenant: tenant}
  end

  describe "photo upload UI" do
    test "renders photo upload section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "Photos of your junk"
      assert html =~ "Tap to add photos"
    end

    test "renders live file input", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "phx-hook=\"Phoenix.LiveFileUpload\""
    end

    test "accepts image files and shows preview", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      photo =
        file_input(view, "form", :photos, [
          %{
            name: "test_photo.jpg",
            content: <<137, 80, 78, 71, 13, 10, 26, 10>>,
            type: "image/jpeg"
          }
        ])

      html = render_upload(photo, "test_photo.jpg")
      # Preview image and cancel button should be present
      assert html =~ "phx-click=\"cancel-upload\""
      assert html =~ "Phoenix.LiveImgPreview"
    end
  end

  describe "form submission with photos" do
    test "form submittable without photos", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "Jane Doe",
            "customer_phone" => "(555) 987-6543",
            "address" => "123 Main St",
            "item_description" => "Old couch"
          }
        })
        |> render_submit()

      assert html =~ "Thank You!"
    end

    test "form submittable with photos", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      # Add a photo
      photo =
        file_input(view, "form", :photos, [
          %{
            name: "junk_photo.jpg",
            content: <<137, 80, 78, 71, 13, 10, 26, 10>>,
            type: "image/jpeg"
          }
        ])

      render_upload(photo, "junk_photo.jpg")

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "Jane Doe",
            "customer_phone" => "(555) 987-6543",
            "address" => "123 Main St",
            "item_description" => "Old couch"
          }
        })
        |> render_submit()

      assert html =~ "Thank You!"
    end
  end

  describe "cancel upload" do
    test "can cancel a selected photo", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      photo =
        file_input(view, "form", :photos, [
          %{
            name: "cancel_me.jpg",
            content: <<137, 80, 78, 71, 13, 10, 26, 10>>,
            type: "image/jpeg"
          }
        ])

      render_upload(photo, "cancel_me.jpg")

      # The photo should be in the entries — cancel it
      assert view |> element("button[phx-click=cancel-upload]") |> render_click()
    end
  end
end
