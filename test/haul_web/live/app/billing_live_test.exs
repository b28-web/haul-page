defmodule HaulWeb.App.BillingLiveTest do
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

  describe "billing page" do
    test "renders billing page with plan cards", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Billing"
      assert html =~ "Starter"
      assert html =~ "Pro"
      assert html =~ "Business"
      assert html =~ "Dedicated"
      assert html =~ "Current Plan"
    end

    test "shows current plan as highlighted", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Current Plan"
      assert html =~ "Upgrade to Pro"
      assert html =~ "Upgrade to Business"
      assert html =~ "Upgrade to Dedicated"
    end

    test "shows correct pricing", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Free"
      assert html =~ "$29/mo"
      assert html =~ "$79/mo"
      assert html =~ "$149/mo"
    end

    test "shows feature labels on plan cards", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "SMS Notifications"
      assert html =~ "Custom Domain"
      assert html =~ "Payment Collection"
      assert html =~ "Crew App"
    end
  end

  describe "upgrade flow" do
    test "upgrade from starter triggers checkout redirect", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      # Click upgrade to Pro — sandbox creates customer + checkout session
      # The sandbox redirects back to billing URL with session_id param
      render_click(view, "select_plan", %{"plan" => "pro"})

      # Verify the company got a stripe_customer_id (side effect of ensure_customer)
      company = Ash.read_one!(Haul.Accounts.Company)
      assert company.stripe_customer_id != nil
      assert String.starts_with?(company.stripe_customer_id, "cus_sandbox_")
    end

    test "upgrade with existing subscription updates plan", %{conn: conn} do
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

    test "upgrade shows correct buttons for pro plan user", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_existing",
          stripe_subscription_id: "sub_existing"
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Downgrade to Starter"
      assert html =~ "Current Plan"
      assert html =~ "Upgrade to Business"
      assert html =~ "Upgrade to Dedicated"
    end
  end

  describe "downgrade flow" do
    test "downgrade shows confirmation modal", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_existing",
          stripe_subscription_id: "sub_existing"
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      html = render_click(view, "select_plan", %{"plan" => "starter"})

      assert html =~ "Confirm Downgrade"
      assert html =~ "Starter"
    end

    test "confirming downgrade changes plan", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_existing",
          stripe_subscription_id: "sub_existing"
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      render_click(view, "select_plan", %{"plan" => "starter"})
      html = render_click(view, "confirm_downgrade")

      assert html =~ "changed to Starter"
    end

    test "cancelling downgrade dismisses modal", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          subscription_plan: :pro,
          stripe_customer_id: "cus_existing",
          stripe_subscription_id: "sub_existing"
        })

      conn = log_in_user(conn, ctx)

      {:ok, view, _html} = live(conn, "/app/settings/billing")

      render_click(view, "select_plan", %{"plan" => "starter"})
      html = render_click(view, "cancel_downgrade")

      refute html =~ "Confirm Downgrade"
    end
  end

  describe "manage billing" do
    test "manage billing button not shown without stripe customer", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      refute html =~ "Manage Payment Methods"
    end

    test "manage billing button shown with stripe customer", %{conn: conn} do
      ctx = create_authenticated_context()

      _company =
        set_company_plan(ctx.company, %{
          stripe_customer_id: "cus_existing"
        })

      conn = log_in_user(conn, ctx)

      {:ok, _view, html} = live(conn, "/app/settings/billing")

      assert html =~ "Manage Payment Methods"
    end
  end

  describe "checkout return" do
    test "session_id param shows success flash", %{conn: conn} do
      {conn, _ctx} = authenticated_conn(conn)

      {:ok, _view, html} = live(conn, "/app/settings/billing?session_id=cs_test_123")

      assert html =~ "plan has been updated successfully"
    end
  end

  describe "authentication" do
    test "redirects unauthenticated users to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app/settings/billing")
    end
  end
end
