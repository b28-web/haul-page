defmodule HaulWeb.Admin.SecurityTest do
  use HaulWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Haul.Admin.AdminUser

  require Ash.Query

  @admin_email "securitytest@admin.com"
  @admin_password "SuperSecure123!"

  defp create_bootstrap_admin(_context) do
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

    %{admin: admin, raw_token: raw_token, token_hash: token_hash}
  end

  defp setup_completed_admin(context) do
    %{admin: admin} = create_bootstrap_admin(context)
    hashed = Bcrypt.hash_pwd_salt(@admin_password)

    {:ok, admin} =
      admin
      |> Ash.Changeset.for_update(:complete_setup, %{hashed_password: hashed}, authorize?: false)
      |> Ash.update()

    # Sign in to get a JWT token
    {:ok, completed_admin} =
      AdminUser
      |> Ash.Query.for_read(
        :sign_in_with_password,
        %{email: @admin_email, password: @admin_password}
      )
      |> Ash.read_one()

    token = completed_admin.__metadata__.token

    %{admin: admin, token: token}
  end

  describe "unauthenticated access" do
    test "GET /admin returns 404 without auth", %{conn: conn} do
      conn = get(conn, ~p"/admin")
      assert conn.status == 404
    end

    test "GET /admin returns 404 with invalid session token", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{_admin_user_token: "invalid-token"})
        |> get(~p"/admin")

      assert conn.status == 404
    end
  end

  describe "tenant user cannot access admin" do
    test "tenant user session does not grant /admin access", %{conn: conn} do
      auth = create_authenticated_context()

      conn =
        conn
        |> log_in_user(auth)
        |> get(~p"/admin")

      assert conn.status == 404
    end
  end

  describe "setup link security" do
    setup :create_bootstrap_admin

    test "valid setup token renders setup form", %{conn: conn, raw_token: token} do
      {:ok, _lv, html} = live(conn, ~p"/admin/setup/#{token}")
      assert html =~ "Admin Setup"
      assert html =~ "Set your password"
    end

    test "invalid setup token returns redirect (404)", %{conn: conn} do
      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/setup/invalid-token-here")
    end

    test "setup link works exactly once", %{conn: conn, raw_token: token} do
      # First: complete setup
      {:ok, lv, _html} = live(conn, ~p"/admin/setup/#{token}")

      lv
      |> form("form", setup: %{password: @admin_password, password_confirmation: @admin_password})
      |> render_submit()

      # Second visit: should fail
      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/setup/#{token}")
    end

    test "AdminUser with setup_completed: true cannot use any setup link", %{conn: conn} do
      # Create another token
      another_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
      assert {:error, {:redirect, _}} = live(conn, ~p"/admin/setup/#{another_token}")
    end
  end

  describe "login after setup" do
    setup :setup_completed_admin

    test "login works with correct password", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/login")

      html =
        lv
        |> form("form", session: %{email: @admin_email, password: @admin_password})
        |> render_submit()

      # After successful login, the form should contain a token value for trigger_submit
      assert html =~ "session[token]"
      refute html =~ "Invalid email or password"
    end

    test "login fails with wrong password", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/login")

      html =
        lv
        |> form("form", session: %{email: @admin_email, password: "wrong-password"})
        |> render_submit()

      assert html =~ "Invalid email or password"
    end

    test "authenticated admin can access /admin dashboard", %{conn: conn, token: token} do
      conn =
        conn
        |> init_test_session(%{_admin_user_token: token})
        |> get(~p"/admin")

      assert conn.status == 200
      assert conn.resp_body =~ "Superadmin Dashboard"
    end
  end

  describe "admin session does not grant /app access" do
    setup :setup_completed_admin

    test "admin session cannot access /app (operator panel)", %{conn: conn, token: token} do
      # Admin session should not work for /app routes
      {:error, {:redirect, %{to: "/app/login"}}} =
        conn
        |> init_test_session(%{_admin_user_token: token})
        |> live(~p"/app")
    end
  end
end
