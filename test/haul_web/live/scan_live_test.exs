defmodule HaulWeb.ScanLiveTest do
  use HaulWeb.ConnCase

  import Phoenix.LiveViewTest

  setup do
    operator = Application.get_env(:haul, :operator)
    %{operator: operator}
  end

  test "GET /scan renders the scan page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Scan to Schedule"
  end

  test "displays operator business name", %{conn: conn, operator: operator} do
    {:ok, _view, html} = live(conn, "/scan")

    assert html =~
             Phoenix.HTML.html_escape(operator[:business_name]) |> Phoenix.HTML.safe_to_string()
  end

  test "displays phone number as tel: link", %{conn: conn, operator: operator} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ operator[:phone]
    digits = String.replace(operator[:phone], ~r/[^\d+]/, "")
    assert html =~ "tel:#{digits}"
  end

  test "contains Book Online CTA linking to /book", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Book Online"
    assert html =~ ~s(href="/book")
  end

  test "renders gallery section with Our Work heading", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Our Work"
    assert html =~ "Before"
    assert html =~ "After"
  end

  test "renders endorsement section with customer names from loader", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "What Customers Say"

    for endorsement <- Haul.Content.Loader.endorsements() do
      assert html =~ endorsement.customer_name
    end
  end

  test "renders star ratings for endorsements", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    # Star icons should be present (hero-star-solid for filled stars)
    assert html =~ "hero-star-solid"
  end

  test "renders footer CTA section", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")
    assert html =~ "Ready to Book?"
  end

  test "renders gallery captions from loader", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/scan")

    for item <- Haul.Content.Loader.gallery_items() do
      if item.caption, do: assert(html =~ item.caption)
    end
  end
end
