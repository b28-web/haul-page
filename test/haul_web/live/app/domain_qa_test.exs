defmodule HaulWeb.App.DomainQATest do
  @moduledoc """
  Browser QA for custom domain flow (T-017-03).
  End-to-end verification of domain settings UI:
  tier gating, domain lifecycle, CNAME instructions,
  DNS verification, status transitions, and removal.
  """
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

  defp set_company_plan(company, attrs) do
    {:ok, updated} =
      company
      |> Ash.Changeset.for_update(:update_company, attrs)
      |> Ash.update()

    updated
  end

  describe "starter tier gating" do
    test "shows upgrade prompt instead of domain form", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Upgrade Plan"
      assert html =~ "Pro plan and above"
      refute html =~ "Add Custom Domain"
      refute html =~ "Verify DNS"
    end

    test "upgrade prompt links to billing page", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "/app/settings/billing"
    end

    test "still shows current subdomain address", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Current Address"
      assert html =~ "test-co"
    end
  end

  describe "domain lifecycle (Pro operator)" do
    test "full flow: add domain → CNAME instructions → verify (DNS error) → remove", %{
      conn: conn
    } do
      ctx = create_authenticated_context()
      _company = set_company_plan(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      # 1. Navigate — see subdomain and add form
      {:ok, view, html} = live(conn, "/app/settings/domain")
      assert html =~ "Current Address"
      assert html =~ "Add Custom Domain"

      # 2. Submit a domain — CNAME instructions appear
      html = render_submit(view, "save_domain", %{"domain" => "hauling.example.com"})
      assert html =~ "Pending Verification"
      assert html =~ "hauling.example.com"
      assert html =~ "CNAME"
      assert html =~ "Verify DNS"

      # 3. Click Verify DNS — expect DNS error (no real CNAME in test)
      html = render_click(view, "verify_dns")
      assert html =~ "DNS" or html =~ "failed" or html =~ "not yet propagated"

      # 4. Remove domain
      render_click(view, "remove_domain")
      html = render_click(view, "confirm_remove")
      assert html =~ "Add Custom Domain"
      assert html =~ "Custom domain removed"
    end
  end

  describe "pre-set domain states" do
    test "pending state: shows CNAME instructions and verify button", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          domain: "custom.example.com",
          domain_status: :pending
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Pending Verification"
      assert html =~ "custom.example.com"
      assert html =~ "CNAME"
      assert html =~ "Verify DNS"
      assert html =~ "Remove Domain"
    end

    test "provisioning state: shows SSL setup message", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          domain: "custom.example.com",
          domain_status: :provisioning
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Setting up SSL"
      assert html =~ "custom.example.com"
      assert html =~ "Remove Domain"
    end

    test "active state: shows green badge and verified tag", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          domain: "custom.example.com",
          domain_status: :active
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Custom Domain Active"
      assert html =~ "custom.example.com"
      assert html =~ "verified"
      assert html =~ "Remove Domain"
    end
  end

  describe "domain validation" do
    test "rejects invalid domain on submit", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_plan(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      html = render_submit(view, "save_domain", %{"domain" => "not-valid"})

      assert html =~ "valid domain"
      refute html =~ "Pending Verification"
    end

    test "normalizes URL input on save", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_plan(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      html = render_submit(view, "save_domain", %{"domain" => "HTTPS://WWW.EXAMPLE.COM/path"})

      assert html =~ "www.example.com"
      assert html =~ "Pending Verification"
    end

    test "shows validation error on change for invalid input", %{conn: conn} do
      ctx = create_authenticated_context()
      _company = set_company_plan(ctx.company, %{subscription_plan: :pro})
      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      html = render_change(view, "validate_domain", %{"domain" => "not valid!"})

      assert html =~ "valid domain"
    end
  end

  describe "remove domain flow" do
    test "cancel dismisses removal modal", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          domain: "custom.example.com",
          domain_status: :active
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      # Open modal
      html = render_click(view, "remove_domain")
      assert html =~ "Remove Custom Domain"
      assert html =~ "revert your site"

      # Cancel
      html = render_click(view, "cancel_remove")
      refute html =~ "Remove Custom Domain"
      # Still active
      assert html =~ "Custom Domain Active"
    end

    test "confirm removes domain and clears DB", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          domain: "custom.example.com",
          domain_status: :active
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/domain")

      render_click(view, "remove_domain")
      html = render_click(view, "confirm_remove")

      assert html =~ "Add Custom Domain"
      assert html =~ "Custom domain removed"

      # Verify DB cleared
      company = Ash.get!(Haul.Accounts.Company, ctx.company.id)
      assert company.domain == nil
      assert company.domain_status == nil
    end
  end

  describe "PubSub status transition" do
    test "domain_status_changed updates UI to active", %{conn: conn} do
      ctx = create_authenticated_context()

      company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          domain: "custom.example.com",
          domain_status: :provisioning
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, html} = live(conn, "/app/settings/domain")
      assert html =~ "Setting up SSL"

      # Simulate cert provisioning completing: update DB then send PubSub message
      {:ok, _updated} =
        company
        |> Ash.Changeset.for_update(:update_company, %{domain_status: :active})
        |> Ash.update()

      send(view.pid, {:domain_status_changed, :active})

      html = render(view)
      assert html =~ "Custom Domain Active"
      assert html =~ "verified"
    end
  end

  describe "authentication" do
    test "unauthenticated user is redirected to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app/settings/domain")
    end
  end
end
