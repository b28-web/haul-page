defmodule HaulWeb.App.SiteConfigLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.SiteConfig

  describe "unauthenticated" do
    test "redirects to /app/login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app/content/site")
    end
  end

  describe "authenticated owner" do
    setup %{conn: conn} do
      ctx = create_authenticated_context(role: :owner)
      conn = log_in_user(conn, ctx)
      tenant = ProvisionTenant.tenant_schema(ctx.company.slug)
      on_exit(fn -> cleanup_tenant(tenant) end)
      %{conn: conn, ctx: ctx, tenant: tenant}
    end

    test "renders site settings form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/content/site")

      assert html =~ "Site Settings"
      assert html =~ "Business Name"
      assert html =~ "Phone"
      assert html =~ "Email"
      assert html =~ "Tagline"
      assert html =~ "Service Area"
      assert html =~ "Primary Color"
    end

    test "saves new config with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/site")

      html =
        view
        |> form("form", site_config: %{business_name: "Test Hauling", phone: "(555) 000-1234"})
        |> render_submit()

      assert html =~ "Site settings updated"
    end

    test "shows validation error for missing required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/site")

      html =
        view
        |> form("form", site_config: %{business_name: "", phone: ""})
        |> render_submit()

      refute html =~ "Site settings updated"
    end

    test "populates form with existing config values", %{conn: conn, tenant: tenant} do
      {:ok, _config} =
        SiteConfig
        |> Ash.Changeset.for_create(
          :create_default,
          %{
            business_name: "Existing Biz",
            phone: "(555) 999-8888",
            tagline: "We haul it all"
          },
          tenant: tenant
        )
        |> Ash.create()

      {:ok, _view, html} = live(conn, "/app/content/site")

      assert html =~ "Existing Biz"
      assert html =~ "(555) 999-8888"
      assert html =~ "We haul it all"
    end

    test "updates existing config", %{conn: conn, tenant: tenant} do
      {:ok, _config} =
        SiteConfig
        |> Ash.Changeset.for_create(
          :create_default,
          %{business_name: "Old Name", phone: "(555) 111-2222"},
          tenant: tenant
        )
        |> Ash.create()

      {:ok, view, _html} = live(conn, "/app/content/site")

      html =
        view
        |> form("form", site_config: %{business_name: "New Name"})
        |> render_submit()

      assert html =~ "Site settings updated"

      # Verify persistence
      {:ok, [config]} = Ash.read(SiteConfig, tenant: tenant)
      assert config.business_name == "New Name"
      assert config.phone == "(555) 111-2222"
    end

    test "validates in real-time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/site")

      # Trigger validation by changing form
      html =
        view
        |> form("form", site_config: %{business_name: "Test", phone: "(555) 123-4567"})
        |> render_change()

      # Should render without errors for valid data
      assert html =~ "Test"
    end

    test "persisted values visible on reload", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/site")

      view
      |> form("form",
        site_config: %{
          business_name: "Reload Test",
          phone: "(555) 777-6666",
          email: "test@example.com"
        }
      )
      |> render_submit()

      # Re-mount the LiveView
      {:ok, _view, html} = live(conn, "/app/content/site")

      assert html =~ "Reload Test"
      assert html =~ "(555) 777-6666"
      assert html =~ "test@example.com"
    end
  end
end
