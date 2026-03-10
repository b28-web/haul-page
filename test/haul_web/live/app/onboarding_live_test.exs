defmodule HaulWeb.App.OnboardingLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Haul.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :auto)

    ctx = Haul.Test.Factories.build_authenticated_context()
    Haul.Content.Seeder.seed!(ctx.tenant)

    Ecto.Adapters.SQL.Sandbox.checkin(Haul.Repo)

    %{ctx: ctx}
  end

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  defp auth_conn(conn, ctx) do
    log_in_user(conn, ctx)
  end

  describe "authentication" do
    test "redirects unauthenticated users to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app/onboarding")
    end

    test "renders for authenticated users", %{conn: conn, ctx: ctx} do
      {:ok, _view, html} = live(auth_conn(conn, ctx), "/app/onboarding")
      assert html =~ "Set Up Your Site"
    end
  end

  describe "step navigation" do
    test "starts at step 1", %{conn: conn, ctx: ctx} do
      {:ok, _view, html} = live(auth_conn(conn, ctx), "/app/onboarding")
      assert html =~ "Step 1 of 6"
      assert html =~ "Confirm Your Info"
    end

    test "can navigate forward with goto", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      html = view |> element("button[phx-value-step='3']") |> render_click()
      assert html =~ "Step 3 of 6"
      assert html =~ "Your Services"
    end

    test "can navigate back", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      # Go to step 3
      view |> element("button[phx-value-step='3']") |> render_click()

      # Go back
      html = view |> element("button", "Back") |> render_click()
      assert html =~ "Step 2 of 6"
    end

    test "next button advances step", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      # Go to step 2 first via goto
      view |> element("button[phx-value-step='2']") |> render_click()

      html = view |> element("button", "Next") |> render_click()
      assert html =~ "Step 3 of 6"
    end
  end

  describe "step 1 - confirm info" do
    test "shows pre-filled site config fields", %{conn: conn, ctx: ctx} do
      {:ok, _view, html} = live(auth_conn(conn, ctx), "/app/onboarding")

      assert html =~ "Business Name"
      assert html =~ "Phone"
      assert html =~ "Email"
      assert html =~ "Service Area"
    end

    test "validates form on change", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      html =
        view
        |> form("form", site_config: %{business_name: ""})
        |> render_change()

      # Form should still render (validation happens server-side)
      assert html =~ "Business Name"
    end

    test "saves info and advances to step 2", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      html =
        view
        |> form("form", site_config: %{business_name: "Updated Biz", phone: "555-1234"})
        |> render_submit()

      assert html =~ "Step 2 of 6"
      assert html =~ "Your Site Address"
    end
  end

  describe "step 2 - your site" do
    test "shows subdomain", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      html = view |> element("button[phx-value-step='2']") |> render_click()
      assert html =~ ctx.company.slug
    end
  end

  describe "step 3 - services" do
    test "shows pre-seeded services", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      html = view |> element("button[phx-value-step='3']") |> render_click()
      assert html =~ "Your Services"
      # Default services should be listed
      assert html =~ "Edit services"
    end
  end

  describe "step 4 - upload logo" do
    test "shows upload form", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      html = view |> element("button[phx-value-step='4']") |> render_click()
      assert html =~ "Upload Your Logo"
      assert html =~ "Click to upload"
    end
  end

  describe "step 5 - preview" do
    test "shows site URL", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      html = view |> element("button[phx-value-step='5']") |> render_click()
      assert html =~ "Preview Your Site"
      assert html =~ "Open Site in New Tab"
    end
  end

  describe "step 6 - go live" do
    test "go live sets onboarding_complete and redirects", %{conn: conn, ctx: ctx} do
      {:ok, view, _html} = live(auth_conn(conn, ctx), "/app/onboarding")

      view |> element("button[phx-value-step='6']") |> render_click()

      assert {:error, {:live_redirect, %{to: "/app"}}} =
               view |> element("button", "Launch My Site") |> render_click()

      # Verify onboarding_complete was set
      updated_company = Ash.get!(Haul.Accounts.Company, ctx.company.id)
      assert updated_company.onboarding_complete == true
    end
  end

  describe "public pages after CLI onboarding" do
    setup do
      params = %{
        name: "Test Hauling",
        phone: "555-0199",
        email: "test@example.com",
        area: "Portland, OR"
      }

      {:ok, result} = Haul.Onboarding.run(params)

      original_operator = Application.get_env(:haul, :operator)

      Application.put_env(
        :haul,
        :operator,
        Keyword.merge(original_operator || [], slug: result.company.slug)
      )

      on_exit(fn ->
        Application.put_env(:haul, :operator, original_operator)
      end)

      %{onboarding_result: result}
    end

    test "landing page renders with onboarded content", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ "555-0199"
      assert html =~ "test@example.com"
      assert html =~ "Portland, OR"
      assert html =~ "What We Do"
    end

    test "landing page displays default services from content pack", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ "Junk Removal"
      assert html =~ "Cleanouts"
    end

    test "scan page renders gallery and endorsements", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/scan")

      assert html =~ "555-0199"
      assert html =~ "Our Work"
      assert html =~ "What Customers Say"
    end

    test "booking page renders form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")

      assert html =~ "</form>"
    end

    test "default content is professional, not placeholder", %{onboarding_result: result} do
      assert length(result.content.services) == 6
      assert length(result.content.gallery_items) == 4
      assert length(result.content.endorsements) == 3
    end

    test "site config updated with operator info", %{onboarding_result: result} do
      [config] = Ash.read!(Haul.Content.SiteConfig, tenant: result.tenant)

      assert config.phone == "555-0199"
      assert config.email == "test@example.com"
      assert config.service_area == "Portland, OR"
    end
  end
end
