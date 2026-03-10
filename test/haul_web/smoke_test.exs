defmodule HaulWeb.SmokeTest do
  @moduledoc """
  Smoke test for all public routes. Asserts every page renders
  without crashing — no DOM assertions, just "does it return 200?"
  """
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    %{tenant: tenant, operator: operator} = create_operator_context()
    %{operator: operator, tenant: tenant}
  end

  describe "public routes render without crashing" do
    test "GET /healthz", %{conn: conn} do
      conn = get(conn, "/healthz")
      assert response(conn, 200)
    end

    test "GET /", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200)
    end

    test "GET /scan", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/scan")
      assert html =~ "</html>"
    end

    test "GET /book", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "</html>"
    end

    test "GET /scan/qr", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr")
      assert response(conn, 200)
    end
  end
end
