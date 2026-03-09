defmodule HaulWeb.PageControllerTest do
  use HaulWeb.ConnCase

  setup do
    operator = Application.get_env(:haul, :operator)
    %{operator: operator}
  end

  test "GET / returns 200 with landing page", %{conn: conn, operator: operator} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    # Business identity from operator config (& is HTML-escaped)
    assert body =~
             Phoenix.HTML.html_escape(operator[:business_name]) |> Phoenix.HTML.safe_to_string()

    assert body =~ operator[:phone]
    assert body =~ operator[:email]
  end

  test "phone number is a tel: link", %{conn: conn, operator: operator} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    digits = String.replace(operator[:phone], ~r/[^\d+]/, "")
    assert body =~ "tel:#{digits}"
  end

  test "email is a mailto: link", %{conn: conn, operator: operator} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    assert body =~ "mailto:#{operator[:email]}"
  end

  test "page contains all section headings", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    assert body =~ "Junk Hauling"
    assert body =~ "What We Do"
    assert body =~ "Why Hire Us"
    assert body =~ "Ready to Get Started?"
  end

  test "page contains all services from config", %{conn: conn, operator: operator} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    for service <- operator[:services] do
      assert body =~ service.title
      assert body =~ service.description
    end
  end

  test "page does not render the app layout navbar", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    # App layout has a navbar with Phoenix version — should not be present
    refute body =~ "navbar"
    refute body =~ "phoenixframework.org"
  end

  test "print button uses progressive enhancement", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    # Button starts hidden, JS shows it
    assert body =~ "window.print()"
    assert body =~ "print-button"
  end
end
