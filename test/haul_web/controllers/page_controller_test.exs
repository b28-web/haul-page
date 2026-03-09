defmodule HaulWeb.PageControllerTest do
  use HaulWeb.ConnCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.Seeder

  setup do
    operator = Application.get_env(:haul, :operator)
    operator_slug = operator[:slug] || "default"

    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Junk & Handy", slug: operator_slug})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)
    Seeder.seed!(tenant)

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

    # Use subdomain host so TenantResolver resolves operator (not platform marketing page)
    %{operator: operator, tenant: tenant, host: "#{operator_slug}.localhost"}
  end

  test "GET / returns 200 with landing page content from Ash", %{conn: conn, host: host} do
    conn = %{conn | host: host} |> get(~p"/")
    body = html_response(conn, 200)

    # Business identity from SiteConfig (seeded from site_config.yml)
    assert body =~ "Junk &amp; Handy"
    assert body =~ "(555) 123-4567"
    assert body =~ "hello@junkandhandy.com"
  end

  test "phone number is a tel: link", %{conn: conn, host: host} do
    conn = %{conn | host: host} |> get(~p"/")
    body = html_response(conn, 200)

    assert body =~ "tel:5551234567"
  end

  test "email is a mailto: link", %{conn: conn, host: host} do
    conn = %{conn | host: host} |> get(~p"/")
    body = html_response(conn, 200)

    assert body =~ "mailto:hello@junkandhandy.com"
  end

  test "page contains all section headings", %{conn: conn, host: host} do
    conn = %{conn | host: host} |> get(~p"/")
    body = html_response(conn, 200)

    assert body =~ "Junk Hauling"
    assert body =~ "What We Do"
    assert body =~ "Why Hire Us"
    assert body =~ "Ready to Get Started?"
  end

  test "page contains services from seeded content", %{conn: conn, host: host, tenant: tenant} do
    conn = %{conn | host: host} |> get(~p"/")
    body = html_response(conn, 200)

    services = Ash.read!(Haul.Content.Service, tenant: tenant)

    for service <- services do
      assert body =~ Phoenix.HTML.html_escape(service.title) |> Phoenix.HTML.safe_to_string()

      assert body =~
               Phoenix.HTML.html_escape(service.description) |> Phoenix.HTML.safe_to_string()
    end
  end

  test "page does not render the app layout navbar", %{conn: conn, host: host} do
    conn = %{conn | host: host} |> get(~p"/")
    body = html_response(conn, 200)

    refute body =~ "navbar"
    refute body =~ "phoenixframework.org"
  end

  test "print button uses progressive enhancement", %{conn: conn, host: host} do
    conn = %{conn | host: host} |> get(~p"/")
    body = html_response(conn, 200)

    assert body =~ "window.print()"
    assert body =~ "print-button"
  end

  test "coupon text comes from SiteConfig", %{conn: conn, host: host} do
    conn = %{conn | host: host} |> get(~p"/")
    body = html_response(conn, 200)

    assert body =~ "10% OFF"
  end
end
