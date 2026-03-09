defmodule HaulWeb.Admin.AccountDetailLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Admin.AdminUser
  alias Haul.Accounts.Company
  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.User

  @admin_email "detail-test@admin.com"
  @admin_password "SuperSecure123!"

  require Ash.Query

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

  defp create_company_with_user(_context) do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Detail Test Co"})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    {:ok, user} =
      User
      |> Ash.Changeset.for_create(
        :register_with_password,
        %{
          email: "user@detail.test",
          password: "Password123!",
          password_confirmation: "Password123!"
        },
        tenant: tenant,
        authorize?: false
      )
      |> Ash.create()

    %{company: company, tenant: tenant, user: user}
  end

  describe "account detail" do
    setup [:setup_admin, :create_company_with_user]

    test "renders company details", %{conn: conn, company: company} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts/#{company.slug}")

      assert html =~ company.name
      assert html =~ company.slug
      assert html =~ "starter"
      assert html =~ "Company Details"
    end

    test "renders users table", %{conn: conn, company: company} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts/#{company.slug}")

      assert html =~ "user@detail.test"
      assert html =~ "Users (1)"
    end

    test "shows status indicators", %{conn: conn, company: company} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts/#{company.slug}")

      assert html =~ "Provisioned"
    end

    test "shows impersonate button (disabled)", %{conn: conn, company: company} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts/#{company.slug}")

      assert html =~ "Impersonate"
      assert html =~ "disabled"
    end

    test "invalid slug redirects to accounts list", %{conn: conn} = ctx do
      {:error, {:live_redirect, %{to: "/admin/accounts", flash: flash}}} =
        admin_conn(conn, ctx)
        |> live(~p"/admin/accounts/nonexistent-slug")

      assert flash["error"] == "Account not found"
    end

    test "back link navigates to accounts list", %{conn: conn, company: company} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts/#{company.slug}")

      assert html =~ "Back to accounts"
      assert html =~ ~p"/admin/accounts"
    end
  end

  describe "account detail security" do
    test "unauthenticated returns 404", %{conn: conn} do
      conn = get(conn, ~p"/admin/accounts/any-slug")
      assert conn.status == 404
    end

    test "tenant user cannot access detail view", %{conn: conn} do
      auth = create_authenticated_context()

      conn =
        conn
        |> log_in_user(auth)
        |> get(~p"/admin/accounts/any-slug")

      assert conn.status == 404
    end
  end
end
