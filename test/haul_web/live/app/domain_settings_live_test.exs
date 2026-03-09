defmodule HaulWeb.App.DomainSettingsLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    on_exit(fn -> cleanup_tenants() end)
    :ok
  end

  defp authenticated_conn(conn, ctx \\ nil) do
    ctx = ctx || create_authenticated_context()
    conn = log_in_user(conn, ctx)
    {conn, ctx}
  end

  defp set_company_attrs(company, attrs) do
    {:ok, updated} =
      company
      |> Ash.Changeset.for_update(:update_company, attrs)
      |> Ash.update()

    updated
  end

  describe "domain settings page" do
    test "renders page for authenticated user", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Domain Settings"
      assert html =~ "Current Address"
    end

    test "shows subdomain address", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "test-co"
    end

    test "redirects unauthenticated users to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app/settings/domain")
    end
  end

  describe "feature gating" do
    test "shows upgrade prompt for starter plan", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Upgrade Plan"
      assert html =~ "Pro plan and above"
    end

    test "shows add domain form for pro plan", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_attrs(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Add Custom Domain"
      refute html =~ "Upgrade Plan"
    end

    test "shows add domain form for business plan", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_attrs(ctx.company, %{subscription_plan: :business})
      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Add Custom Domain"
    end
  end

  describe "add domain" do
    test "validates domain format on change", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_attrs(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      html = render_change(view, "validate_domain", %{"domain" => "not valid!"})

      assert html =~ "valid domain"
    end

    test "saves valid domain", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_attrs(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      html = render_submit(view, "save_domain", %{"domain" => "www.example.com"})

      assert html =~ "Pending Verification"
      assert html =~ "www.example.com"
      assert html =~ "CNAME"
    end

    test "normalizes domain input on save", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_attrs(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      html = render_submit(view, "save_domain", %{"domain" => "HTTPS://WWW.EXAMPLE.COM/path"})

      assert html =~ "www.example.com"
      assert html =~ "Pending Verification"
    end

    test "rejects invalid domain on save", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_attrs(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      html = render_submit(view, "save_domain", %{"domain" => "not-valid"})

      assert html =~ "valid domain"
      refute html =~ "Pending Verification"
    end
  end

  describe "pending verification state" do
    test "shows CNAME instructions for pending domain", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_attrs(ctx.company, %{
          subscription_plan: :pro,
          domain: "www.example.com",
          domain_status: :pending
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Pending Verification"
      assert html =~ "CNAME"
      assert html =~ "www.example.com"
      assert html =~ "Verify DNS"
    end

    test "shows verify button", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_attrs(ctx.company, %{
          subscription_plan: :pro,
          domain: "www.example.com",
          domain_status: :pending
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Verify DNS"
    end
  end

  describe "remove domain" do
    test "shows confirmation modal", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_attrs(ctx.company, %{
          subscription_plan: :pro,
          domain: "www.example.com",
          domain_status: :active
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      html = render_click(view, "remove_domain")

      assert html =~ "Remove Custom Domain"
      assert html =~ "www.example.com"
    end

    test "removes domain on confirm", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_attrs(ctx.company, %{
          subscription_plan: :pro,
          domain: "www.example.com",
          domain_status: :active
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      render_click(view, "remove_domain")
      html = render_click(view, "confirm_remove")

      assert html =~ "Add Custom Domain"
      assert html =~ "Custom domain removed"

      # Verify domain cleared in DB
      company = Ash.read_one!(Haul.Accounts.Company)
      assert company.domain == nil
      assert company.domain_status == nil
    end

    test "cancels remove dismisses modal", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_attrs(ctx.company, %{
          subscription_plan: :pro,
          domain: "www.example.com",
          domain_status: :active
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      render_click(view, "remove_domain")
      html = render_click(view, "cancel_remove")

      refute html =~ "Remove Custom Domain"
    end
  end

  describe "active domain state" do
    test "shows active domain with green badge", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_attrs(ctx.company, %{
          subscription_plan: :pro,
          domain: "www.example.com",
          domain_status: :active
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Custom Domain Active"
      assert html =~ "www.example.com"
      assert html =~ "verified"
    end
  end
end
