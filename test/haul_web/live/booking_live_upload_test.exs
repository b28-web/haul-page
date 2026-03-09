defmodule HaulWeb.BookingLiveUploadTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company

  setup do
    operator = Application.get_env(:haul, :operator)

    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: operator[:business_name],
        slug: operator[:slug]
      })
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

    test "accepts image files", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      photo =
        file_input(view, "form", :photos, [
          %{
            name: "test_photo.jpg",
            content: <<137, 80, 78, 71, 13, 10, 26, 10>>,
            type: "image/jpeg"
          }
        ])

      assert render_upload(photo, "test_photo.jpg") =~ "test_photo.jpg"
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
