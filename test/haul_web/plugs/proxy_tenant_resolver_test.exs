defmodule HaulWeb.Plugs.ProxyTenantResolverTest do
  use HaulWeb.ConnCase

  alias Haul.Accounts.Company
  alias HaulWeb.Plugs.ProxyTenantResolver

  defp create_company(slug, opts \\ []) do
    attrs = %{name: opts[:name] || "Test Co #{slug}", slug: slug}

    Company
    |> Ash.Changeset.for_create(:create_company, attrs)
    |> Ash.create!()
  end

  defp resolve(conn, slug) do
    conn
    |> Map.put(:path_params, %{"slug" => slug})
    |> Plug.Test.init_test_session(%{})
    |> ProxyTenantResolver.call(ProxyTenantResolver.init([]))
  end

  describe "slug resolution" do
    test "resolves company by slug", %{conn: conn} do
      company = create_company("joes-hauling", name: "Joe's Hauling")

      conn = resolve(conn, "joes-hauling")

      assert conn.assigns.current_tenant.id == company.id
      assert conn.assigns.current_tenant.slug == "joes-hauling"
      assert conn.assigns.tenant == "tenant_joes-hauling"
      assert conn.assigns.proxy_slug == "joes-hauling"
      assert conn.assigns.is_platform_host == false
    end

    test "resolves different companies by slug", %{conn: conn} do
      _joe = create_company("joes-hauling")
      bob = create_company("bobs-removal")

      conn = resolve(conn, "bobs-removal")

      assert conn.assigns.current_tenant.id == bob.id
      assert conn.assigns.tenant == "tenant_bobs-removal"
      assert conn.assigns.proxy_slug == "bobs-removal"
    end
  end

  describe "404 behavior" do
    test "unknown slug returns 404", %{conn: conn} do
      conn = resolve(conn, "nonexistent")

      assert conn.halted
      assert conn.status == 404
    end

    test "nil slug returns 404", %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_params, %{})
        |> Plug.Test.init_test_session(%{})
        |> ProxyTenantResolver.call(ProxyTenantResolver.init([]))

      assert conn.halted
      assert conn.status == 404
    end
  end

  describe "session storage" do
    test "stores tenant_slug and proxy_slug in session", %{conn: conn} do
      create_company("joes-hauling")
      conn = resolve(conn, "joes-hauling")

      assert Plug.Conn.get_session(conn, "tenant_slug") == "joes-hauling"
      assert Plug.Conn.get_session(conn, "proxy_slug") == "joes-hauling"
    end
  end
end
