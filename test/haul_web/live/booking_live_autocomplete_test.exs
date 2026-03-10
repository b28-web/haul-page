defmodule HaulWeb.BookingLiveAutocompleteTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    %{tenant: tenant, operator: operator} = create_operator_context()
    %{operator: operator, tenant: tenant}
  end

  describe "address autocomplete hook" do
    test "address input has phx-hook attribute", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ ~s(phx-hook="AddressAutocomplete")
    end

    test "address input has autocomplete off to prevent browser autocomplete", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ ~s(autocomplete="off")
    end

    test "address input has stable id for hook", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ ~s(id="address-autocomplete")
    end

    test "address input is wrapped in relative container for dropdown positioning", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      # The relative div wraps the input for absolute dropdown positioning
      assert html =~ ~s(class="relative")
    end

    test "form submission works with manually typed address (graceful degradation)", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "/book")

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "Jane Doe",
            "customer_phone" => "(555) 987-6543",
            "address" => "742 Evergreen Terrace, Springfield",
            "item_description" => "Old furniture"
          }
        })
        |> render_submit()

      assert html =~ "Thank You!"
    end

    test "form validation works with address value present", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "Jane",
            "customer_phone" => "555-1234",
            "address" => "123 Test St",
            "item_description" => "Junk"
          }
        })
        |> render_change()

      assert html =~ "Book a Pickup"
      refute html =~ "is required"
    end

    test "form validation shows error when address is empty after interaction", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/book")

      # First interact with a value, then clear it
      view
      |> form("form", %{
        "form" => %{
          "customer_name" => "Jane",
          "customer_phone" => "555-1234",
          "address" => "123 Test",
          "item_description" => "Junk"
        }
      })
      |> render_change()

      html =
        view
        |> form("form", %{
          "form" => %{
            "customer_name" => "Jane",
            "customer_phone" => "555-1234",
            "address" => "",
            "item_description" => "Junk"
          }
        })
        |> render_change()

      assert html =~ "is required"
    end
  end

  describe "places API integration" do
    test "autocomplete endpoint returns suggestions for valid input", %{conn: conn} do
      conn = get(conn, "/api/places/autocomplete?input=123+Main")

      assert %{"suggestions" => suggestions} = json_response(conn, 200)
      assert is_list(suggestions)
      assert length(suggestions) > 0
    end

    test "autocomplete endpoint returns empty for short input", %{conn: conn} do
      conn = get(conn, "/api/places/autocomplete?input=ab")

      assert %{"suggestions" => []} = json_response(conn, 200)
    end
  end
end
