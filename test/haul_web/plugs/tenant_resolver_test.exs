defmodule HaulWeb.Plugs.TenantResolverTest do
  use HaulWeb.ConnCase

  alias Haul.Accounts.Company
  alias HaulWeb.Plugs.TenantResolver

  defp create_company(slug, opts \\ []) do
    attrs = %{name: opts[:name] || "Test Co #{slug}", slug: slug}
    attrs = if opts[:domain], do: Map.put(attrs, :domain, opts[:domain]), else: attrs

    Company
    |> Ash.Changeset.for_create(:create_company, attrs)
    |> Ash.create!()
  end

  defp resolve(conn, host) do
    conn
    |> Map.put(:host, host)
    |> Plug.Test.init_test_session(%{})
    |> TenantResolver.call(TenantResolver.init([]))
  end

  describe "subdomain resolution" do
    test "resolves company by subdomain", %{conn: conn} do
      company = create_company("joes-hauling", name: "Joe's Hauling")

      conn = resolve(conn, "joes-hauling.haulpage.test")

      assert conn.assigns.current_tenant.id == company.id
      assert conn.assigns.current_tenant.slug == "joes-hauling"
      assert conn.assigns.tenant == "tenant_joes-hauling"
    end

    test "resolves different companies by subdomain", %{conn: conn} do
      _joe = create_company("joes-hauling")
      bob = create_company("bobs-removal")

      conn = resolve(conn, "bobs-removal.haulpage.test")

      assert conn.assigns.current_tenant.id == bob.id
      assert conn.assigns.tenant == "tenant_bobs-removal"
    end
  end

  describe "custom domain resolution" do
    test "resolves company by custom domain", %{conn: conn} do
      company = create_company("joes-hauling", domain: "www.joeshauling.com")

      conn = resolve(conn, "www.joeshauling.com")

      assert conn.assigns.current_tenant.id == company.id
      assert conn.assigns.tenant == "tenant_joes-hauling"
    end

    test "custom domain takes priority over subdomain", %{conn: conn} do
      # A company with a custom domain that happens to look like a subdomain of another domain
      company = create_company("special", domain: "special.haulpage.test")

      conn = resolve(conn, "special.haulpage.test")

      # Should resolve via custom domain first
      assert conn.assigns.current_tenant.id == company.id
    end
  end

  describe "fallback behavior" do
    test "unknown host falls back to demo tenant", %{conn: conn} do
      conn = resolve(conn, "unknown.example.com")

      assert conn.assigns.current_tenant == nil
      assert conn.assigns.tenant == "tenant_junk-and-handy"
    end

    test "bare base domain falls back to demo tenant", %{conn: conn} do
      conn = resolve(conn, "haulpage.test")

      assert conn.assigns.current_tenant == nil
      assert conn.assigns.tenant == "tenant_junk-and-handy"
    end

    test "localhost falls back to demo tenant", %{conn: conn} do
      conn = resolve(conn, "localhost")

      assert conn.assigns.current_tenant == nil
      assert conn.assigns.tenant == "tenant_junk-and-handy"
    end

    test "unknown subdomain falls back to demo tenant", %{conn: conn} do
      conn = resolve(conn, "nonexistent.haulpage.test")

      assert conn.assigns.current_tenant == nil
      assert conn.assigns.tenant == "tenant_junk-and-handy"
    end
  end

  describe "session storage" do
    test "stores company slug in session on subdomain match", %{conn: conn} do
      create_company("joes-hauling")
      conn = resolve(conn, "joes-hauling.haulpage.test")
      assert Plug.Conn.get_session(conn, "tenant_slug") == "joes-hauling"
    end

    test "stores fallback slug in session when no match", %{conn: conn} do
      conn = resolve(conn, "unknown.example.com")
      assert Plug.Conn.get_session(conn, "tenant_slug") == "junk-and-handy"
    end
  end

  describe "extract_subdomain/2" do
    test "extracts subdomain from host" do
      assert TenantResolver.extract_subdomain("joes.haulpage.com", "haulpage.com") == "joes"
    end

    test "returns nil for bare base domain" do
      assert TenantResolver.extract_subdomain("haulpage.com", "haulpage.com") == nil
    end

    test "returns nil for unrelated host" do
      assert TenantResolver.extract_subdomain("example.com", "haulpage.com") == nil
    end

    test "handles nested subdomains" do
      assert TenantResolver.extract_subdomain("sub.domain.haulpage.com", "haulpage.com") ==
               "sub.domain"
    end
  end
end
