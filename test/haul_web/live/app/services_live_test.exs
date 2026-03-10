defmodule HaulWeb.App.ServicesLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Content.Service

  describe "unauthenticated" do
    test "redirects to /app/login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app/content/services")
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

    test "renders services page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/content/services")

      assert html =~ "Services"
      assert html =~ "Add Service"
    end

    test "renders existing services", %{conn: conn, tenant: tenant} do
      create_service(tenant, %{
        title: "Junk Removal",
        description: "We haul junk",
        icon: "hero-truck",
        sort_order: 1
      })

      {:ok, _view, html} = live(conn, "/app/content/services")

      assert html =~ "Junk Removal"
      assert html =~ "We haul junk"
    end

    test "adds a new service", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/services")

      view |> element("button", "Add Service") |> render_click()

      html =
        view
        |> form("form",
          service: %{title: "New Service", description: "A new offering", icon: "hero-star"}
        )
        |> render_submit()

      assert html =~ "Service added"
      assert html =~ "New Service"
      assert html =~ "A new offering"
    end

    test "validates form in real-time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/services")

      view |> element("button", "Add Service") |> render_click()

      html =
        view
        |> form("form", service: %{title: "Test", description: "Desc", icon: "hero-truck"})
        |> render_change()

      assert html =~ "Test"
    end

    test "edits an existing service", %{conn: conn, tenant: tenant} do
      service =
        create_service(tenant, %{
          title: "Old Title",
          description: "Old desc",
          icon: "hero-truck",
          sort_order: 1
        })

      {:ok, view, _html} = live(conn, "/app/content/services")

      view |> render_click("edit", %{"id" => service.id})

      html =
        view
        |> form("form", service: %{title: "Updated Title"})
        |> render_submit()

      assert html =~ "Service updated"
      assert html =~ "Updated Title"
    end

    test "deletes a service with confirmation", %{conn: conn, tenant: tenant} do
      create_service(tenant, %{
        title: "Keep Me",
        description: "Staying",
        icon: "hero-truck",
        sort_order: 1
      })

      svc =
        create_service(tenant, %{
          title: "Delete Me",
          description: "Going away",
          icon: "hero-trash",
          sort_order: 2
        })

      {:ok, view, html} = live(conn, "/app/content/services")
      assert html =~ "Delete Me"

      # Click delete on the target service
      view |> render_click("delete", %{"id" => svc.id})

      # Verify confirmation dialog is shown
      html = render(view)
      assert html =~ "cannot be undone"

      # Confirm deletion
      view |> render_click("confirm_delete", %{})

      # Verify persistence first
      services = Ash.read!(Service, tenant: tenant)
      assert length(services) == 1
      assert hd(services).title == "Keep Me"
    end

    test "cannot delete the last service", %{conn: conn, tenant: tenant} do
      _svc =
        create_service(tenant, %{
          title: "Only One",
          description: "The only service",
          icon: "hero-truck",
          sort_order: 1
        })

      {:ok, _view, html} = live(conn, "/app/content/services")

      # Delete button should not be rendered when only 1 service exists
      refute html =~ "phx-click=\"delete\""
    end

    test "reorders services with move up", %{conn: conn, tenant: tenant} do
      create_service(tenant, %{
        title: "First",
        description: "First service",
        icon: "hero-truck",
        sort_order: 1
      })

      svc2 =
        create_service(tenant, %{
          title: "Second",
          description: "Second service",
          icon: "hero-star",
          sort_order: 2
        })

      {:ok, view, _html} = live(conn, "/app/content/services")

      view |> render_click("move_up", %{"id" => svc2.id})

      # Reload to verify persistence
      {:ok, _view, html} = live(conn, "/app/content/services")

      # Second should now appear before First in the DOM
      first_pos = :binary.match(html, "Second") |> elem(0)
      second_pos = :binary.match(html, "First") |> elem(0)
      assert first_pos < second_pos
    end

    test "reorders services with move down", %{conn: conn, tenant: tenant} do
      svc1 =
        create_service(tenant, %{
          title: "Alpha",
          description: "First",
          icon: "hero-truck",
          sort_order: 1
        })

      create_service(tenant, %{
        title: "Beta",
        description: "Second",
        icon: "hero-star",
        sort_order: 2
      })

      {:ok, view, _html} = live(conn, "/app/content/services")

      view |> render_click("move_down", %{"id" => svc1.id})

      {:ok, _view, html} = live(conn, "/app/content/services")

      beta_pos = :binary.match(html, "Beta") |> elem(0)
      alpha_pos = :binary.match(html, "Alpha") |> elem(0)
      assert beta_pos < alpha_pos
    end

    test "cancel closes the form", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/content/services")

      view |> element("button", "Add Service") |> render_click()
      html = view |> element("button", "Cancel") |> render_click()

      refute html =~ "Add Service</h2>"
    end
  end

  defp create_service(tenant, attrs) do
    Service
    |> Ash.Changeset.for_create(:add, attrs, tenant: tenant)
    |> Ash.create!()
  end
end
