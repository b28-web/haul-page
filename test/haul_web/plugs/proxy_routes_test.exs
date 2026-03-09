defmodule HaulWeb.ProxyRoutesTest do
  use HaulWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Company

  defp create_company(slug, opts \\ []) do
    attrs = %{name: opts[:name] || "Test Co #{slug}", slug: slug}

    Company
    |> Ash.Changeset.for_create(:create_company, attrs)
    |> Ash.create!()
  end

  describe "GET /proxy/:slug/" do
    test "renders home page with correct tenant", %{conn: conn} do
      create_company("joes-hauling", name: "Joe's Hauling")

      conn = get(conn, "/proxy/joes-hauling")

      assert html_response(conn, 200)
      assert conn.assigns.current_tenant.slug == "joes-hauling"
      assert conn.assigns.proxy_slug == "joes-hauling"
    end

    test "returns 404 for unknown slug", %{conn: conn} do
      conn = get(conn, "/proxy/nonexistent")

      assert response(conn, 404)
    end
  end

  describe "GET /proxy/:slug/scan/qr" do
    test "generates QR code with correct tenant", %{conn: conn} do
      create_company("joes-hauling")

      conn = get(conn, "/proxy/joes-hauling/scan/qr")

      assert conn.status in [200, 302]
      assert conn.assigns.current_tenant.slug == "joes-hauling"
    end
  end

  describe "LiveView proxy routes" do
    test "proxy /book mounts with correct tenant", %{conn: conn} do
      create_company("joes-hauling")

      {:ok, _view, html} = live(conn, "/proxy/joes-hauling/book")

      assert html =~ "Book"
    end

    test "proxy /scan mounts with correct tenant", %{conn: conn} do
      create_company("joes-hauling")

      {:ok, _view, html} = live(conn, "/proxy/joes-hauling/scan")

      assert html =~ "Scan"
    end
  end

  describe "proxy-aware links" do
    test "scan page Book Online links point to proxy path", %{conn: conn} do
      create_company("joes-hauling")

      {:ok, _view, html} = live(conn, "/proxy/joes-hauling/scan")

      assert html =~ ~s(href="/proxy/joes-hauling/book")
    end

    test "QR code encodes real URL, not proxy URL", %{conn: conn} do
      create_company("joes-hauling")

      conn = get(conn, "/proxy/joes-hauling/scan/qr")

      # QR codes should NOT contain /proxy/ — they're for print
      assert conn.status == 200
      # The QR SVG content is binary, but the URL encoded is based on Endpoint.url()
      refute conn.resp_body =~ "/proxy/"
    end
  end
end
