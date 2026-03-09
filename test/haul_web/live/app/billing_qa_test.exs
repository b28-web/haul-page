defmodule HaulWeb.App.BillingQATest do
  @moduledoc """
  Browser QA for subscription billing (T-016-04).
  End-to-end verification of upgrade UI, plan state changes,
  feature gate activation, downgrade flow, and dunning alerts.
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

  describe "billing page initial state (Starter plan)" do
    test "renders all four tier comparison cards", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Starter"
      assert html =~ "Pro"
      assert html =~ "Business"
      assert html =~ "Dedicated"
    end

    test "displays Starter as current plan with Free pricing", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Current Plan"
      assert html =~ "Free"
      # Other plans show their prices
      assert html =~ "$29/mo"
      assert html =~ "$79/mo"
      assert html =~ "$149/mo"
    end

    test "shows upgrade buttons for Pro, Business, Dedicated", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Upgrade to Pro"
      assert html =~ "Upgrade to Business"
      assert html =~ "Upgrade to Dedicated"
      # No downgrade button on Starter
      refute html =~ "Downgrade"
    end

    test "shows feature labels on plan cards", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "SMS Notifications"
      assert html =~ "Custom Domain"
      assert html =~ "Payment Collection"
      assert html =~ "Crew App"
    end

    test "does not show Manage Payment Methods without Stripe customer", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      refute html =~ "Manage Payment Methods"
    end
  end

  describe "upgrade flow" do
    test "clicking Upgrade to Pro creates sandbox customer and triggers checkout", %{conn: conn} do
      {conn, ctx} = authenticated_conn(conn)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      # Trigger upgrade — sandbox adapter creates customer + checkout session
      render_click(view, "select_plan", %{"plan" => "pro"})

      # Verify the company got a sandbox stripe_customer_id
      company = Ash.get!(Haul.Accounts.Company, ctx.company.id)
      assert company.stripe_customer_id != nil
      assert String.starts_with?(company.stripe_customer_id, "cus_sandbox_")
    end

    test "returning with session_id shows success flash", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing?session_id=cs_sandbox_test")

      assert html =~ "plan has been updated successfully"
    end

    test "billing page reflects Pro as current plan after upgrade", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_sandbox_123",
          stripe_subscription_id: "sub_sandbox_123"
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      # Pro is now current
      assert html =~ "Downgrade to Starter"
      assert html =~ "Upgrade to Business"
      assert html =~ "Upgrade to Dedicated"
      # Manage Payment Methods now visible
      assert html =~ "Manage Payment Methods"
    end

    test "upgrading existing subscription updates plan immediately", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_existing",
          stripe_subscription_id: "sub_existing"
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      html = render_click(view, "select_plan", %{"plan" => "business"})

      assert html =~ "upgraded to Business"
    end
  end

  describe "feature gate verification" do
    test "Starter plan: domain settings shows upgrade prompt", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Upgrade Plan"
      assert html =~ "Custom domains are available on the Pro plan"
      refute html =~ "Add Custom Domain"
    end

    test "Pro plan: domain settings shows custom domain form", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_sandbox_123",
          stripe_subscription_id: "sub_sandbox_123"
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Add Custom Domain"
      refute html =~ "Upgrade Plan"
    end
  end

  describe "downgrade flow" do
    test "clicking downgrade to Starter shows confirmation modal", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_sandbox_123",
          stripe_subscription_id: "sub_sandbox_123"
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      html = render_click(view, "select_plan", %{"plan" => "starter"})

      assert html =~ "Confirm Downgrade"
      assert html =~ "Starter"
    end

    test "confirming downgrade changes plan back to Starter", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_sandbox_123",
          stripe_subscription_id: "sub_sandbox_123"
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      # Open modal then confirm
      render_click(view, "select_plan", %{"plan" => "starter"})
      html = render_click(view, "confirm_downgrade")

      assert html =~ "changed to Starter"
    end

    test "after downgrade to Starter, domain settings shows upgrade prompt", %{conn: conn} do
      ctx = create_authenticated_context()

      # Start on Pro, then downgrade
      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_sandbox_123",
          stripe_subscription_id: "sub_sandbox_123"
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      # Downgrade
      render_click(view, "select_plan", %{"plan" => "starter"})
      render_click(view, "confirm_downgrade")

      # Check domain settings now shows upgrade prompt
      {:ok, _view, html} = live(conn, "/app/settings/domain")

      assert html =~ "Upgrade Plan"
      refute html =~ "Add Custom Domain"
    end
  end

  describe "dunning alert" do
    test "shows payment issue warning when dunning_started_at is set", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_sandbox_123",
          stripe_subscription_id: "sub_sandbox_123",
          dunning_started_at: DateTime.utc_now()
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Payment issue"
      assert html =~ "payment failed"
      assert html =~ "days"
    end
  end

  describe "authentication" do
    test "unauthenticated user is redirected to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app/settings/billing")
    end
  end
end
