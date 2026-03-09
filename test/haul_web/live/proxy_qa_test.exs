defmodule HaulWeb.ProxyQATest do
  @moduledoc """
  Browser QA for the dev proxy system (T-022-03).
  Verifies end-to-end proxy routing: tenant resolution, content rendering,
  link navigation, LiveView functionality, and cross-tenant isolation.
  """
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.{Service, SiteConfig}

  setup do
    on_exit(fn -> cleanup_tenants() end)

    company_a = create_company_with_content("alpha-hauling", "Alpha Hauling Co", "555-1111")
    company_b = create_company_with_content("beta-removal", "Beta Removal Inc", "555-2222")

    %{company_a: company_a, company_b: company_b}
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
      %{title: "#{name} Junk Removal", description: "Full-service junk removal", icon: "hero-truck", sort_order: 1},
      tenant: tenant
    )
    |> Ash.create!()

    %{company: company, tenant: tenant, slug: slug, name: name, phone: phone}
  end

  describe "proxy landing page" do
    test "renders with tenant business name and services", %{conn: conn, company_a: a} do
      conn = get(conn, "/proxy/#{a.slug}")
      html = html_response(conn, 200)

      assert html =~ a.name
      assert html =~ a.phone
      assert html =~ "What We Do"
      assert html =~ "#{a.name} Junk Removal"
    end

    test "renders tagline and service area", %{conn: conn, company_a: a} do
      conn = get(conn, "/proxy/#{a.slug}")
      html = html_response(conn, 200)

      assert html =~ "#{a.name} — we haul it all"
      assert html =~ "#{a.name} Metro"
    end
  end

  describe "proxy scan page" do
    test "mounts LiveView with scan content", %{conn: conn, company_a: a} do
      {:ok, _view, html} = live(conn, "/proxy/#{a.slug}/scan")

      assert html =~ "Scan"
      assert html =~ a.name
    end

    test "Book Online link stays in proxy namespace", %{conn: conn, company_a: a} do
      {:ok, _view, html} = live(conn, "/proxy/#{a.slug}/scan")

      assert html =~ ~s(href="/proxy/#{a.slug}/book")
    end
  end

  describe "proxy booking form" do
    test "mounts LiveView under proxy", %{conn: conn, company_a: a} do
      {:ok, _view, html} = live(conn, "/proxy/#{a.slug}/book")

      assert html =~ "Book"
    end

    test "form validate event works under proxy", %{conn: conn, company_a: a} do
      {:ok, view, _html} = live(conn, "/proxy/#{a.slug}/book")

      # Trigger form validation — should not crash
      html =
        view
        |> form("form", %{})
        |> render_change()

      assert is_binary(html)
    end
  end

  describe "proxy chat" do
    test "mounts or redirects gracefully under proxy", %{conn: conn, company_a: a} do
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
    test "different slugs show different business names", %{conn: conn, company_a: a, company_b: b} do
      conn_a = get(conn, "/proxy/#{a.slug}")
      html_a = html_response(conn_a, 200)

      conn_b = get(build_conn(), "/proxy/#{b.slug}")
      html_b = html_response(conn_b, 200)

      assert html_a =~ a.name
      assert html_b =~ b.name
      refute html_a =~ b.name
      refute html_b =~ a.name
    end

    test "different slugs show different phone numbers", %{conn: conn, company_a: a, company_b: b} do
      conn_a = get(conn, "/proxy/#{a.slug}")
      html_a = html_response(conn_a, 200)

      conn_b = get(build_conn(), "/proxy/#{b.slug}")
      html_b = html_response(conn_b, 200)

      assert html_a =~ a.phone
      assert html_b =~ b.phone
      refute html_a =~ b.phone
      refute html_b =~ a.phone
    end

    test "scan pages show different tenant content", %{conn: conn, company_a: a, company_b: b} do
      {:ok, _view, html_a} = live(conn, "/proxy/#{a.slug}/scan")
      {:ok, _view, html_b} = live(build_conn(), "/proxy/#{b.slug}/scan")

      assert html_a =~ a.name
      assert html_b =~ b.name
      refute html_a =~ b.name
      refute html_b =~ a.name
    end
  end

  describe "LiveView WebSocket under proxy" do
    test "scan page re-renders after mount", %{conn: conn, company_a: a} do
      {:ok, view, _html} = live(conn, "/proxy/#{a.slug}/scan")

      html = render(view)
      assert html =~ "Scan"
      assert html =~ a.name
    end

    test "booking form interaction works", %{conn: conn, company_a: a} do
      {:ok, view, _html} = live(conn, "/proxy/#{a.slug}/book")

      html = render(view)
      assert html =~ "Book"
    end
  end

  describe "error handling" do
    test "unknown slug returns 404", %{conn: conn} do
      conn = get(conn, "/proxy/nonexistent-tenant")
      assert response(conn, 404)
    end
  end
end
