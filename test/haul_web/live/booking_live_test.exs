defmodule HaulWeb.BookingLiveTest do
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

  describe "rendering" do
    test "GET /book renders the booking form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "Book a Pickup"
    end

    test "shows required field labels", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "Your Name"
      assert html =~ "Phone Number"
      assert html =~ "Pickup Address"
      assert html =~ "What do you need picked up?"
    end

    test "shows email field", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "Email (optional)"
    end

    test "shows preferred dates section", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "Preferred Dates (optional)"
    end

    test "phone input uses tel type", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ ~s(type="tel")
    end

    test "email input uses email type", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ ~s(type="email")
    end

    test "date inputs use date type", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ ~s(type="date")
    end

    test "shows photo upload label with max count", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "up to 5"
    end

    test "shows operator phone for direct contact", %{conn: conn, operator: operator} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ operator[:phone]
      assert html =~ "Or call us directly"
    end
  end

  describe "form submission" do
    test "successful submission shows confirmation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "Jane Doe",
            "customer_phone" => "(555) 987-6543",
            "customer_email" => "jane@example.com",
            "address" => "123 Main St, Anytown, USA",
            "item_description" => "Old couch and mattress"
          }
        })
        |> render_submit()

      assert html =~ "Thank You!"
      assert html =~ "We&#39;ll contact you shortly"
    end

    test "confirmation shows operator phone", %{conn: conn, operator: operator} do
      {:ok, view, _html} = live(conn, "/book")

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "Jane Doe",
            "customer_phone" => "(555) 987-6543",
            "address" => "123 Main St",
            "item_description" => "Junk"
          }
        })
        |> render_submit()

      assert html =~ operator[:phone]
      assert html =~ "Submit Another Request"
    end

    test "reset returns to form after submission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      view
      |> form("form", %{
        "form" => %{
          "customer_name" => "Jane Doe",
          "customer_phone" => "(555) 987-6543",
          "address" => "123 Main St",
          "item_description" => "Stuff"
        }
      })
      |> render_submit()

      html = render_click(view, "reset")
      assert html =~ "Book a Pickup"
      assert html =~ "Your Name"
    end
  end

  describe "validation" do
    test "shows errors when submitting empty form", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "",
            "customer_phone" => "",
            "address" => "",
            "item_description" => ""
          }
        })
        |> render_submit()

      assert html =~ "is required"
    end

    test "validates on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "Jane",
            "customer_phone" => "",
            "address" => "",
            "item_description" => ""
          }
        })
        |> render_change()

      # After change, the form should still be rendered (no crash)
      assert html =~ "Book a Pickup"
    end
  end
end
