defmodule HaulWeb.Admin.AccountsLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  require Ash.Query

  @company_names ["Alpha Hauling", "Beta Junk Removal"]

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

    # Clean up stale data from prior runs (targeted — only this file's companies)
    for name <- @company_names do
      slug = name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")
      Ecto.Adapters.SQL.query(Haul.Repo, "DROP SCHEMA IF EXISTS \"tenant_#{slug}\" CASCADE")
      Ecto.Adapters.SQL.query(Haul.Repo, "DELETE FROM companies WHERE name = $1", [name])
    end

    # Clean stale admin_users from previous runs (setup_all + :auto commits permanently)
    Ecto.Adapters.SQL.query(Haul.Repo, "DELETE FROM admin_users")

    %{admin: _admin, token: admin_token} = Haul.Test.Factories.build_admin_session()

    company1 = Haul.Test.Factories.build_company(%{name: "Alpha Hauling"})
    company2 = Haul.Test.Factories.build_company(%{name: "Beta Junk Removal"})

    Ecto.Adapters.SQL.Sandbox.checkin(Haul.Repo)

    %{admin_token: admin_token, company1: company1, company2: company2}
  end

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  defp admin_conn(conn, %{admin_token: token}) do
    conn |> init_test_session(%{_admin_user_token: token})
  end

  describe "accounts list" do
    test "renders accounts table", %{conn: conn} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")

      assert html =~ "Accounts"
      assert html =~ "alpha-hauling"
      assert html =~ "Beta Junk Removal"
      assert html =~ "beta-junk-removal"
    end

    test "search filters by name", %{conn: conn} = ctx do
      {:ok, lv, _html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")

      html = lv |> element("form") |> render_change(%{search: "alpha"})
      assert html =~ "alpha-hauling"
      refute html =~ "beta-junk-removal"
    end

    test "search filters by slug", %{conn: conn} = ctx do
      {:ok, lv, _html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")

      html = lv |> element("form") |> render_change(%{search: "beta"})
      assert html =~ "beta-junk-removal"
      refute html =~ "alpha-hauling"
    end

    test "sort toggles direction", %{conn: conn} = ctx do
      {:ok, lv, _html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")

      # Sort by name ascending
      html = lv |> element("button", "Business Name") |> render_click()
      assert html =~ "↑"

      # Toggle to descending
      html = lv |> element("button", "Business Name") |> render_click()
      assert html =~ "↓"
    end

    test "shows status indicators", %{conn: conn} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")

      # Both companies are provisioned (create_company provisions tenant)
      assert html =~ "Tenant provisioned"
    end

    test "row click navigates to detail", %{conn: conn, company1: company1} = ctx do
      {:ok, lv, _html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")

      lv |> element("tr[phx-value-slug=#{company1.slug}]") |> render_click()
      assert_redirect(lv, ~p"/admin/accounts/#{company1.slug}")
    end

    test "shows total count", %{conn: conn} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")
      assert html =~ "total"
    end
  end

  describe "accounts list security" do
    test "unauthenticated returns 404", %{conn: conn} do
      conn = get(conn, ~p"/admin/accounts")
      assert conn.status == 404
    end

    test "invalid admin token returns 404", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{_admin_user_token: "invalid-token"})
        |> get(~p"/admin/accounts")

      assert conn.status == 404
    end

    test "tenant user cannot access accounts list", %{conn: conn} do
      auth = Haul.Test.Factories.build_authenticated_context()

      conn =
        conn
        |> log_in_user(auth)
        |> get(~p"/admin/accounts")

      assert conn.status == 404
    end
  end
end
