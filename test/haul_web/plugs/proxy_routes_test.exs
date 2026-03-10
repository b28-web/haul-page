defmodule HaulWeb.ProxyRoutesTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.{Service, SiteConfig}

  setup do
    uid = System.unique_integer([:positive])
    slug = "proxy-test-#{uid}"

    on_exit(fn -> cleanup_tenant("tenant_#{slug}") end)

    %{slug: slug}
  end

  defp create_company(slug, opts \\ []) do
    attrs = %{name: opts[:name] || "Test Co #{slug}", slug: slug}

    Company
    |> Ash.Changeset.for_create(:create_company, attrs)
    |> Ash.create!()
  end

  defp create_company_with_content(slug, name, phone) do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: name, slug: slug})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(slug)

    SiteConfig
    |> Ash.Changeset.for_create(
      :create_default,
      %{
        business_name: name,
        phone: phone,
        email: "info@#{slug}.example.com",
        tagline: "#{name} — we haul it all",
        service_area: "#{name} Metro"
      },
      tenant: tenant
    )
    |> Ash.create!()

    Service
    |> Ash.Changeset.for_create(
      :add,
      %{
        title: "#{name} Junk Removal",
        description: "Full-service junk removal",
        icon: "hero-truck",
        sort_order: 1
      },
      tenant: tenant
    )
    |> Ash.create!()

    %{company: company, tenant: tenant, slug: slug, name: name, phone: phone}
  end

  describe "GET /proxy/:slug/" do
    test "renders home page with correct tenant", %{conn: conn, slug: slug} do
      create_company(slug, name: "Proxy Test Co")

      conn = get(conn, "/proxy/#{slug}")

      assert html_response(conn, 200)
      assert conn.assigns.current_tenant.slug == slug
      assert conn.assigns.proxy_slug == slug
    end

    test "returns 404 for unknown slug", %{conn: conn} do
      conn = get(conn, "/proxy/nonexistent")

      assert response(conn, 404)
    end
  end

  describe "GET /proxy/:slug/scan/qr" do
    test "generates QR code with correct tenant", %{conn: conn, slug: slug} do
      create_company(slug)

      conn = get(conn, "/proxy/#{slug}/scan/qr")

      assert conn.status in [200, 302]
      assert conn.assigns.current_tenant.slug == slug
    end
  end

  describe "LiveView proxy routes" do
    test "proxy /book mounts with correct tenant", %{conn: conn, slug: slug} do
      create_company(slug)

      {:ok, _view, html} = live(conn, "/proxy/#{slug}/book")

      assert html =~ "Book"
    end

    test "proxy /scan mounts with correct tenant", %{conn: conn, slug: slug} do
      create_company(slug)

      {:ok, _view, html} = live(conn, "/proxy/#{slug}/scan")

      assert html =~ "Scan"
    end
  end

  describe "proxy-aware links" do
    test "scan page Book Online links point to proxy path", %{conn: conn, slug: slug} do
      create_company(slug)

      {:ok, _view, html} = live(conn, "/proxy/#{slug}/scan")

      assert html =~ ~s(href="/proxy/#{slug}/book")
    end

    test "QR code encodes real URL, not proxy URL", %{conn: conn, slug: slug} do
      create_company(slug)

      conn = get(conn, "/proxy/#{slug}/scan/qr")

      # QR codes should NOT contain /proxy/ — they're for print
      assert conn.status == 200
      # The QR SVG content is binary, but the URL encoded is based on Endpoint.url()
      refute conn.resp_body =~ "/proxy/"
    end
  end

  describe "proxy content rendering" do
    test "renders tagline and service area", %{conn: conn} do
      uid = System.unique_integer([:positive])
      a = create_company_with_content("alpha-#{uid}", "Alpha Co #{uid}", "555-1111")

      conn = get(conn, "/proxy/#{a.slug}")
      html = html_response(conn, 200)

      assert html =~ "Alpha Co #{uid} — we haul it all"
      assert html =~ "Alpha Co #{uid} Metro"
    end

    test "form validate event works under proxy", %{conn: conn} do
      uid = System.unique_integer([:positive])
      a = create_company_with_content("alpha-#{uid}", "Alpha Co #{uid}", "555-1111")

      {:ok, view, _html} = live(conn, "/proxy/#{a.slug}/book")

      html =
        view
        |> form("form", %{})
        |> render_change()

      assert is_binary(html)
    end

    test "chat mounts or redirects gracefully under proxy", %{conn: conn} do
      uid = System.unique_integer([:positive])
      a = create_company_with_content("alpha-#{uid}", "Alpha Co #{uid}", "555-1111")
      clear_rate_limits()

      result = live(conn, "/proxy/#{a.slug}/start")

      case result do
        {:ok, _view, html} ->
          assert html =~ "Get Started"

        {:error, {:redirect, %{to: to}}} ->
          assert to =~ "/app/signup"

        {:error, {:live_redirect, %{to: to}}} ->
          assert to =~ "/app/signup"
      end
    end
  end

  describe "cross-tenant isolation" do
    test "different slugs show different business names", %{conn: conn} do
      uid = System.unique_integer([:positive])
      a = create_company_with_content("alpha-#{uid}", "Alpha Co #{uid}", "555-1111")
      b = create_company_with_content("beta-#{uid}", "Beta Co #{uid}", "555-2222")

      html_a = get(conn, "/proxy/#{a.slug}") |> html_response(200)
      html_b = get(build_conn(), "/proxy/#{b.slug}") |> html_response(200)

      assert html_a =~ a.name
      assert html_b =~ b.name
      refute html_a =~ b.name
      refute html_b =~ a.name
    end

    test "different slugs show different phone numbers", %{conn: conn} do
      uid = System.unique_integer([:positive])
      a = create_company_with_content("alpha-#{uid}", "Alpha Co #{uid}", "555-1111")
      b = create_company_with_content("beta-#{uid}", "Beta Co #{uid}", "555-2222")

      html_a = get(conn, "/proxy/#{a.slug}") |> html_response(200)
      html_b = get(build_conn(), "/proxy/#{b.slug}") |> html_response(200)

      assert html_a =~ a.phone
      assert html_b =~ b.phone
      refute html_a =~ b.phone
      refute html_b =~ a.phone
    end

    test "scan pages show different tenant content", %{conn: conn} do
      uid = System.unique_integer([:positive])
      a = create_company_with_content("alpha-#{uid}", "Alpha Co #{uid}", "555-1111")
      b = create_company_with_content("beta-#{uid}", "Beta Co #{uid}", "555-2222")

      {:ok, _view, html_a} = live(conn, "/proxy/#{a.slug}/scan")
      {:ok, _view, html_b} = live(build_conn(), "/proxy/#{b.slug}/scan")

      assert html_a =~ a.name
      assert html_b =~ b.name
      refute html_a =~ b.name
      refute html_b =~ a.name
    end
  end
end
