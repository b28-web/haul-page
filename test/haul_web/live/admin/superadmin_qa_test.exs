defmodule HaulWeb.Admin.SuperadminQATest do
  @moduledoc """
  Browser QA for the superadmin panel (T-023-04).
  End-to-end flow: login → accounts → detail → impersonate → verify → exit.
  Security: regular users and unauthenticated visitors get 404.
  """
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Content.{Service, SiteConfig}

  setup do
    on_exit(fn -> cleanup_tenants() end)

    admin_ctx = create_admin_session()
    target = create_company_with_content("qa-target", "QA Target Co", "555-9999")
    other = create_company_with_content("qa-other", "QA Other Co", "555-8888")
    user_ctx = create_authenticated_context()

    %{
      admin: admin_ctx,
      target: target,
      other: other,
      user: user_ctx
    }
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
        tagline: "#{name} — professional hauling",
        service_area: "#{name} Metro"
      },
      tenant: tenant
    )
    |> Ash.create!()

    Service
    |> Ash.Changeset.for_create(
      :add,
      %{
        title: "#{name} Junk Removal",
        description: "Full-service",
        icon: "hero-truck",
        sort_order: 1
      },
      tenant: tenant
    )
    |> Ash.create!()

    %{company: company, tenant: tenant, slug: slug, name: name, phone: phone}
  end

  defp admin_conn(conn, %{admin: %{token: token}}) do
    conn |> init_test_session(%{_admin_user_token: token})
  end

  defp impersonation_conn(admin_token, slug, admin_id) do
    build_conn()
    |> init_test_session(%{
      "_admin_user_token" => admin_token,
      "impersonating_slug" => slug,
      "impersonating_since" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "real_admin_id" => admin_id
    })
  end

  # ── Superadmin login and dashboard ──

  describe "superadmin login and dashboard" do
    test "admin can access dashboard", %{conn: conn} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin")

      assert html =~ "Dashboard"
    end

    test "dashboard shows admin email", %{conn: conn, admin: admin} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin")

      assert html =~ to_string(admin.admin.email)
    end
  end

  # ── Accounts list ──

  describe "accounts list" do
    test "shows test companies", %{conn: conn, target: target, other: other} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")

      assert html =~ target.name
      assert html =~ other.name
    end

    test "shows company slugs", %{conn: conn, target: target} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts")

      assert html =~ target.slug
    end
  end

  # ── Account detail ──

  describe "account detail" do
    test "shows company info", %{conn: conn, target: target} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts/#{target.slug}")

      assert html =~ target.name
      assert html =~ target.slug
      assert html =~ "Company Details"
    end

    test "shows impersonate button", %{conn: conn, target: target} = ctx do
      {:ok, _lv, html} = live(admin_conn(conn, ctx), ~p"/admin/accounts/#{target.slug}")

      assert html =~ "Impersonate"
      assert html =~ "/admin/impersonate/#{target.slug}"
    end
  end

  # ── Impersonation flow ──

  describe "impersonation flow" do
    test "start impersonation redirects to /app", %{conn: conn, target: target} = ctx do
      conn =
        admin_conn(conn, ctx)
        |> post(~p"/admin/impersonate/#{target.slug}")

      assert redirected_to(conn) == "/app"
      assert get_session(conn, "impersonating_slug") == target.slug
    end

    test "impersonation banner visible with company info", %{admin: admin, target: target} do
      conn = impersonation_conn(admin.token, target.slug, admin.admin.id)

      {:ok, _lv, html} = live(conn, ~p"/app")

      assert html =~ "Viewing as"
      assert html =~ target.name
      assert html =~ target.slug
      assert html =~ "Exit Impersonation"
    end

    test "tenant content matches impersonated company", %{
      admin: admin,
      target: target,
      other: other
    } do
      conn = impersonation_conn(admin.token, target.slug, admin.admin.id)

      {:ok, _lv, html} = live(conn, ~p"/app")

      # Banner shows target company, not the other
      assert html =~ target.name
      refute html =~ other.name
    end

    test "exit impersonation returns to admin accounts", %{admin: admin, target: target} do
      conn = impersonation_conn(admin.token, target.slug, admin.admin.id)

      conn = post(conn, ~p"/admin/exit-impersonation")

      assert redirected_to(conn) == "/admin/accounts"
      refute get_session(conn, "impersonating_slug")
      refute get_session(conn, "impersonating_since")
    end

    test "/admin/accounts accessible after exit",
         %{conn: conn, admin: admin, target: target} = ctx do
      # Start impersonation
      conn =
        admin_conn(conn, ctx)
        |> post(~p"/admin/impersonate/#{target.slug}")

      assert redirected_to(conn) == "/app"

      # Exit impersonation
      conn =
        build_conn()
        |> init_test_session(%{
          "_admin_user_token" => admin.token,
          "impersonating_slug" => target.slug,
          "impersonating_since" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "real_admin_id" => admin.admin.id
        })
        |> post(~p"/admin/exit-impersonation")

      assert redirected_to(conn) == "/admin/accounts"

      # Admin can access accounts after exit
      {:ok, _lv, html} = live(admin_conn(build_conn(), ctx), ~p"/admin/accounts")
      assert html =~ "Accounts"
    end
  end

  # ── Privilege stacking blocked ──

  describe "privilege stacking blocked" do
    test "/admin returns 404 during impersonation", %{admin: admin, target: target} do
      conn = impersonation_conn(admin.token, target.slug, admin.admin.id)

      conn = get(conn, ~p"/admin")
      assert conn.status == 404
    end

    test "/admin/accounts returns 404 during impersonation", %{admin: admin, target: target} do
      conn = impersonation_conn(admin.token, target.slug, admin.admin.id)

      conn = get(conn, ~p"/admin/accounts")
      assert conn.status == 404
    end

    test "/admin/accounts/:slug returns 404 during impersonation", %{admin: admin, target: target} do
      conn = impersonation_conn(admin.token, target.slug, admin.admin.id)

      conn = get(conn, ~p"/admin/accounts/#{target.slug}")
      assert conn.status == 404
    end
  end

  # ── Security: regular user access ──

  describe "security: regular user access" do
    test "regular user gets 404 on /admin", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/admin")

      assert conn.status == 404
    end

    test "regular user gets 404 on /admin/accounts/:slug", %{
      conn: conn,
      user: user,
      target: target
    } do
      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/admin/accounts/#{target.slug}")

      assert conn.status == 404
    end

    test "unauthenticated gets 404 on /admin", %{conn: conn} do
      conn = get(conn, ~p"/admin")
      assert conn.status == 404
    end

    test "unauthenticated gets 404 on /admin/accounts", %{conn: conn} do
      conn = get(conn, ~p"/admin/accounts")
      assert conn.status == 404
    end
  end
end
