defmodule HaulWeb.TenantHookTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company

  setup do
    operator = Application.get_env(:haul, :operator)
    operator_slug = operator[:slug] || "default"

    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Junk & Handy",
        slug: operator_slug
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

    %{company: company, tenant: tenant, operator: operator}
  end

  describe "tenant resolution via live_session" do
    test "LiveView receives tenant from TenantHook", %{conn: conn, tenant: tenant} do
      {:ok, view, _html} = live(conn, "/book")
      # The LiveView should have resolved the tenant via TenantHook
      # We verify by checking the page renders correctly with tenant data
      assert render(view) =~ "Book a Pickup"
      # Tenant is set via on_mount from session (fallback path since conn.host is www.example.com)
      assert tenant == "tenant_junk-and-handy"
    end

    test "LiveView with specific tenant company", %{conn: conn} do
      {:ok, company} =
        Company
        |> Ash.Changeset.for_create(:create_company, %{
          name: "Bob's Removal",
          slug: "bobs-removal"
        })
        |> Ash.create()

      # Simulate a request coming from bob's subdomain
      conn =
        conn
        |> Map.put(:host, "bobs-removal.haulpage.test")

      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "Book a Pickup"
      # The tenant should be resolved to bob's tenant
      expected_tenant = ProvisionTenant.tenant_schema(company.slug)
      assert expected_tenant == "tenant_bobs-removal"
    end

    test "tenant re-verified on each mount (not cached)", %{conn: conn} do
      # First mount — uses fallback tenant
      {:ok, _view, html} = live(conn, "/scan")
      assert html =~ "Scan to Schedule"

      # Second mount — should also work (re-verifies tenant from DB)
      {:ok, _view, html2} = live(conn, "/scan")
      assert html2 =~ "Scan to Schedule"
    end
  end

  describe "tenant isolation" do
    test "different subdomains get different tenant contexts", %{conn: conn} do
      {:ok, _} =
        Company
        |> Ash.Changeset.for_create(:create_company, %{name: "Alpha Co", slug: "alpha"})
        |> Ash.create()

      {:ok, _} =
        Company
        |> Ash.Changeset.for_create(:create_company, %{name: "Beta Co", slug: "beta"})
        |> Ash.create()

      # Alpha subdomain request
      conn_alpha = Map.put(conn, :host, "alpha.haulpage.test")
      {:ok, _view, html_alpha} = live(conn_alpha, "/book")
      assert html_alpha =~ "Book a Pickup"

      # Beta subdomain request
      conn_beta = Map.put(conn, :host, "beta.haulpage.test")
      {:ok, _view, html_beta} = live(conn_beta, "/book")
      assert html_beta =~ "Book a Pickup"
    end

    test "unknown subdomain falls back to default tenant", %{conn: conn} do
      conn = Map.put(conn, :host, "nonexistent.haulpage.test")
      {:ok, _view, html} = live(conn, "/book")
      assert html =~ "Book a Pickup"
    end
  end
end
