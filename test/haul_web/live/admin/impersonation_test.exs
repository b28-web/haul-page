defmodule HaulWeb.Admin.ImpersonationTest do
  use HaulWeb.ConnCase, async: true

  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest

  alias HaulWeb.Impersonation

  setup %{conn: conn} do
    admin_ctx = create_admin_session()
    tenant_ctx = create_authenticated_context()

    conn = log_in_admin(conn, admin_ctx)
    %{conn: conn, admin: admin_ctx.admin, admin_token: admin_ctx.token, tenant: tenant_ctx}
  end

  defp impersonation_session(token, slug, admin_id) do
    %{
      "_admin_user_token" => token,
      "impersonating_slug" => slug,
      "impersonating_since" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "real_admin_id" => admin_id
    }
  end

  describe "Impersonation helper" do
    test "active?/1 detects impersonation keys" do
      assert Impersonation.active?(%{"impersonating_slug" => "test"})
      refute Impersonation.active?(%{})
      refute Impersonation.active?(%{"impersonating_slug" => nil})
    end

    test "expired?/1 detects expired sessions" do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      refute Impersonation.expired?(%{"impersonating_since" => now})

      two_hours_ago =
        DateTime.utc_now()
        |> DateTime.add(-7200, :second)
        |> DateTime.to_iso8601()

      assert Impersonation.expired?(%{"impersonating_since" => two_hours_ago})
    end

    test "remaining_minutes/1 calculates correctly" do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      remaining = Impersonation.remaining_minutes(%{"impersonating_since" => now})
      assert remaining in 59..60

      thirty_min_ago =
        DateTime.utc_now()
        |> DateTime.add(-1800, :second)
        |> DateTime.to_iso8601()

      remaining = Impersonation.remaining_minutes(%{"impersonating_since" => thirty_min_ago})
      assert remaining in 29..30
    end
  end

  describe "start impersonation" do
    test "POST /admin/impersonate/:slug redirects to /app", %{conn: conn, tenant: tenant} do
      conn = post(conn, ~p"/admin/impersonate/#{tenant.company.slug}")
      assert redirected_to(conn) == "/app"

      # Verify session keys are set
      assert get_session(conn, "impersonating_slug") == tenant.company.slug
      assert get_session(conn, "impersonating_since")
      assert get_session(conn, "real_admin_id")
    end

    test "POST /admin/impersonate/:slug logs audit event", %{conn: conn, tenant: tenant} do
      log =
        capture_log(fn ->
          post(conn, ~p"/admin/impersonate/#{tenant.company.slug}")
        end)

      assert log =~ "Impersonation started"
      assert log =~ tenant.company.slug
    end

    test "POST /admin/impersonate/nonexistent returns error flash", %{conn: conn} do
      conn = post(conn, ~p"/admin/impersonate/nonexistent-slug")
      assert redirected_to(conn) == "/admin/accounts"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Account not found"
    end

    test "unauthenticated POST /admin/impersonate returns 404" do
      conn = build_conn()
      conn = post(conn, ~p"/admin/impersonate/test-slug")
      assert conn.status == 404
    end
  end

  describe "exit impersonation" do
    test "POST /admin/exit-impersonation clears keys and redirects", %{
      tenant: tenant,
      admin: admin,
      admin_token: token
    } do
      conn =
        build_conn()
        |> init_test_session(impersonation_session(token, tenant.company.slug, admin.id))
        |> post(~p"/admin/exit-impersonation")

      assert redirected_to(conn) == "/admin/accounts"
      refute get_session(conn, "impersonating_slug")
      refute get_session(conn, "impersonating_since")
      refute get_session(conn, "real_admin_id")
    end

    test "exit impersonation logs audit event", %{
      tenant: tenant,
      admin: admin,
      admin_token: token
    } do
      conn =
        build_conn()
        |> init_test_session(impersonation_session(token, tenant.company.slug, admin.id))

      log =
        capture_log(fn ->
          post(conn, ~p"/admin/exit-impersonation")
        end)

      assert log =~ "Impersonation manual"
    end

    test "unauthenticated exit returns 404" do
      conn = build_conn()
      conn = post(conn, ~p"/admin/exit-impersonation")
      assert conn.status == 404
    end
  end

  describe "privilege stacking" do
    test "/admin returns 404 during impersonation", %{
      tenant: tenant,
      admin: admin,
      admin_token: token
    } do
      conn =
        build_conn()
        |> init_test_session(impersonation_session(token, tenant.company.slug, admin.id))
        |> get(~p"/admin")

      assert conn.status == 404
    end

    test "/admin/accounts returns 404 during impersonation", %{
      admin_token: token,
      tenant: tenant,
      admin: admin
    } do
      conn =
        build_conn()
        |> init_test_session(impersonation_session(token, tenant.company.slug, admin.id))
        |> get(~p"/admin/accounts")

      assert conn.status == 404
    end
  end

  describe "tenant user cannot impersonate" do
    test "tenant user session with impersonation keys are ignored", %{tenant: tenant} do
      conn =
        build_conn()
        |> init_test_session(%{
          "user_token" => tenant.token,
          "tenant" => tenant.tenant,
          "impersonating_slug" => tenant.company.slug,
          "impersonating_since" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "real_admin_id" => "fake-admin-id"
        })
        |> get(~p"/admin")

      # Without valid admin session, these keys are ignored
      assert conn.status == 404
    end
  end

  describe "admin logout clears impersonation" do
    test "DELETE /admin/session clears impersonation keys", %{
      admin_token: token,
      tenant: tenant,
      admin: admin
    } do
      # Admin logout goes through the public /admin scope (no RequireAdmin)
      # So we can test it even with impersonation keys set
      conn =
        build_conn()
        |> init_test_session(
          Map.put(
            impersonation_session(token, tenant.company.slug, admin.id),
            "_admin_user_token",
            token
          )
        )
        |> delete(~p"/admin/session")

      assert redirected_to(conn) == "/admin/login"
      refute get_session(conn, "impersonating_slug")
    end
  end

  describe "impersonation expiry" do
    test "expired impersonation is detected by helper" do
      two_hours_ago =
        DateTime.utc_now()
        |> DateTime.add(-7200, :second)
        |> DateTime.to_iso8601()

      session = %{
        "impersonating_slug" => "test",
        "impersonating_since" => two_hours_ago,
        "real_admin_id" => "some-id"
      }

      assert Impersonation.active?(session)
      assert Impersonation.expired?(session)
      assert Impersonation.remaining_minutes(session) == 0
    end
  end

  describe "impersonate button on account detail" do
    test "shows impersonate button for provisioned account", %{conn: conn, tenant: tenant} do
      {:ok, _lv, html} = live(conn, ~p"/admin/accounts/#{tenant.company.slug}")
      assert html =~ "Impersonate"
      assert html =~ "/admin/impersonate/#{tenant.company.slug}"
    end
  end
end
