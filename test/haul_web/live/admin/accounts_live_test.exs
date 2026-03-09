defmodule HaulWeb.Admin.AccountsLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Admin.AdminUser
  alias Haul.Accounts.Company

  @admin_email "accounts-test@admin.com"
  @admin_password "SuperSecure123!"

  defp setup_admin(_context) do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)

    {:ok, admin} =
      AdminUser
      |> Ash.Changeset.for_create(
        :create_bootstrap,
        %{email: @admin_email, setup_token_hash_value: token_hash},
        authorize?: false
      )
      |> Ash.create()

    hashed = Bcrypt.hash_pwd_salt(@admin_password)

    {:ok, _admin} =
      admin
      |> Ash.Changeset.for_update(:complete_setup, %{hashed_password: hashed}, authorize?: false)
      |> Ash.update()

    {:ok, completed_admin} =
      AdminUser
      |> Ash.Query.for_read(
        :sign_in_with_password,
        %{email: @admin_email, password: @admin_password}
      )
      |> Ash.read_one()

    token = completed_admin.__metadata__.token
    %{admin_token: token}
  end

  defp admin_conn(conn, %{admin_token: token}) do
    conn |> init_test_session(%{_admin_user_token: token})
  end

  defp create_companies(_context) do
    {:ok, company1} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Alpha Hauling"})
      |> Ash.create()

    {:ok, company2} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Beta Junk Removal"})
      |> Ash.create()

    %{company1: company1, company2: company2}
  end

  require Ash.Query

  describe "accounts list" do
    setup [:setup_admin, :create_companies]

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
      auth = create_authenticated_context()

      conn =
        conn
        |> log_in_user(auth)
        |> get(~p"/admin/accounts")

      assert conn.status == 404
    end
  end
end
