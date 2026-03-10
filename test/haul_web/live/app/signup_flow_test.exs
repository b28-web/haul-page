defmodule HaulWeb.App.SignupFlowTest do
  @moduledoc """
  End-to-end browser QA for the self-service signup flow (T-015-04).
  Tests the complete journey: marketing page → signup → onboarding → live site.
  """
  use HaulWeb.ConnCase, async: false

  require Logger

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Company

  setup do
    clear_rate_limits()
    :ok
  end

  defp marketing_conn(conn) do
    %{conn | host: "haulpage.test"}
  end

  defp conn_with_ip(conn, ip \\ nil) do
    ip = ip || "10.0.0.#{System.unique_integer([:positive, :monotonic])}"
    Phoenix.ConnTest.init_test_session(conn, %{"remote_ip" => ip})
  end

  describe "marketing page to signup" do
    test "marketing page loads on bare domain with CTAs", %{conn: conn} do
      conn = marketing_conn(conn)
      conn = get(conn, ~p"/")
      body = html_response(conn, 200)

      # Hero section
      assert body =~ "Your Hauling Business Online in 2 Minutes"
      # CTA
      assert body =~ "Get Started Free"
      assert body =~ "/app/signup"
    end

    test "marketing page has pricing tiers", %{conn: conn} do
      conn = marketing_conn(conn)
      conn = get(conn, ~p"/")
      body = html_response(conn, 200)

      assert body =~ "Starter"
      assert body =~ "Pro"
      assert body =~ "$29"
      assert body =~ "Business"
      assert body =~ "$79"
    end

    test "marketing page has features section", %{conn: conn} do
      conn = marketing_conn(conn)
      conn = get(conn, ~p"/")
      body = html_response(conn, 200)

      assert body =~ "Professional Website"
      assert body =~ "Online Booking"
      assert body =~ "Mobile Ready"
    end

    test "marketing page has how-it-works section", %{conn: conn} do
      conn = marketing_conn(conn)
      conn = get(conn, ~p"/")
      body = html_response(conn, 200)

      assert body =~ "How It Works"
      assert body =~ "Sign Up"
      assert body =~ "Customize"
      assert body =~ "Get Customers"
    end
  end

  describe "signup form" do
    test "renders all required fields", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/signup")

      assert html =~ "Business Name"
      assert html =~ "Email"
      assert html =~ "Phone"
      assert html =~ "Password"
      assert html =~ "Create My Site"
    end

    test "slug preview updates on name input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form", signup: %{name: "QA Test Hauling"})
        |> render_change()

      assert html =~ "qa-test-hauling"
      assert html =~ "Your site:"
    end

    test "shows availability for new slug", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form", signup: %{name: "Totally Unique QA Biz"})
        |> render_change()

      assert html =~ "Available"
    end

    test "validates missing name", %{conn: conn} do
      conn = conn_with_ip(conn)
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form",
          signup: %{
            name: "",
            email: "test@example.com",
            password: "Password123!",
            password_confirmation: "Password123!"
          }
        )
        |> render_submit()

      assert html =~ "name is required"
    end

    test "validates short password", %{conn: conn} do
      conn = conn_with_ip(conn)
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form",
          signup: %{
            name: "Test Biz",
            email: "test@example.com",
            password: "short",
            password_confirmation: "short"
          }
        )
        |> render_submit()

      assert html =~ "password must be at least 8 characters"
    end

    test "validates password mismatch", %{conn: conn} do
      conn = conn_with_ip(conn)
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form",
          signup: %{
            name: "Test Biz",
            email: "test@example.com",
            password: "Password123!",
            password_confirmation: "WrongPassword!"
          }
        )
        |> render_submit()

      assert html =~ "passwords do not match"
    end
  end

  describe "complete signup flow" do
    test "signup creates company, user, and content", %{conn: conn} do
      t_start = System.monotonic_time(:millisecond)

      conn = conn_with_ip(conn)
      {:ok, view, _html} = live(conn, "/app/signup")

      # Fill and submit signup form
      html =
        view
        |> form("form",
          signup: %{
            name: "Flow Test Co",
            email: "flow@example.com",
            phone: "555-FLOW",
            area: "Seattle, WA",
            password: "Password123!",
            password_confirmation: "Password123!"
          }
        )
        |> render_submit()

      t_signup = System.monotonic_time(:millisecond)

      # Should trigger form submission to /app/session
      assert html =~ "phx-trigger-action"

      # Verify company was created
      companies = Ash.read!(Company)
      flow_co = Enum.find(companies, &(&1.slug == "flow-test-co"))
      assert flow_co, "Company 'flow-test-co' should exist after signup"
      assert flow_co.name == "Flow Test Co"

      # Verify tenant schema was provisioned
      tenant = "tenant_flow-test-co"
      configs = Ash.read!(Haul.Content.SiteConfig, tenant: tenant)
      assert length(configs) > 0, "SiteConfig should be seeded"

      config = hd(configs)
      assert config.phone == "555-FLOW"
      assert config.email == "flow@example.com"
      assert config.service_area == "Seattle, WA"

      # Verify services were seeded
      services = Ash.read!(Haul.Content.Service, tenant: tenant)
      assert length(services) >= 4, "Default services should be seeded"

      # Verify gallery items seeded
      gallery = Ash.read!(Haul.Content.GalleryItem, tenant: tenant)
      assert length(gallery) >= 3, "Default gallery items should be seeded"

      # Verify endorsements seeded
      endorsements = Ash.read!(Haul.Content.Endorsement, tenant: tenant)
      assert length(endorsements) >= 3, "Default endorsements should be seeded"

      # Log timing
      signup_ms = t_signup - t_start
      Logger.info("[T-015-04 timing] Signup completed in #{signup_ms}ms")
    end

    test "signup followed by onboarding wizard walkthrough", %{conn: conn} do
      t_start = System.monotonic_time(:millisecond)

      # Use Onboarding.signup to create the full context
      {:ok, result} =
        Haul.Onboarding.signup(%{
          name: "Wizard Test Co",
          email: "wizard@example.com",
          phone: "555-WIZD",
          area: "Portland, OR",
          password: "Password123!",
          password_confirmation: "Password123!"
        })

      t_signup = System.monotonic_time(:millisecond)

      # Set up authenticated session
      auth_conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{
          user_token: result.user.__metadata__.token,
          tenant: result.tenant
        })

      # Mount onboarding
      {:ok, view, html} = live(auth_conn, "/app/onboarding")
      assert html =~ "Step 1 of 6"
      assert html =~ "Confirm Your Info"

      # Step 2: Your Site
      html = view |> element("button[phx-value-step='2']") |> render_click()
      assert html =~ "Step 2 of 6"
      assert html =~ result.company.slug

      # Step 3: Services
      html = view |> element("button[phx-value-step='3']") |> render_click()
      assert html =~ "Step 3 of 6"
      assert html =~ "Your Services"

      # Step 4: Upload Logo
      html = view |> element("button[phx-value-step='4']") |> render_click()
      assert html =~ "Step 4 of 6"
      assert html =~ "Upload Your Logo"

      # Step 5: Preview
      html = view |> element("button[phx-value-step='5']") |> render_click()
      assert html =~ "Step 5 of 6"
      assert html =~ "Preview Your Site"

      # Step 6: Go Live
      view |> element("button[phx-value-step='6']") |> render_click()

      assert {:error, {:live_redirect, %{to: "/app"}}} =
               view |> element("button", "Launch My Site") |> render_click()

      t_live = System.monotonic_time(:millisecond)

      # Verify onboarding_complete was set
      updated = Ash.get!(Company, result.company.id)
      assert updated.onboarding_complete == true

      # Log timing
      signup_ms = t_signup - t_start
      live_ms = t_live - t_start
      Logger.info("[T-015-04 timing] Signup: #{signup_ms}ms, Total to live: #{live_ms}ms")
    end

    test "tenant site renders after onboarding", %{conn: conn} do
      # Create and complete onboarding
      {:ok, result} =
        Haul.Onboarding.signup(%{
          name: "Site Render Co",
          email: "render@example.com",
          phone: "555-SITE",
          area: "Denver, CO",
          password: "Password123!",
          password_confirmation: "Password123!"
        })

      # Configure operator to point at this tenant for content resolution
      original_operator = Application.get_env(:haul, :operator)

      Application.put_env(
        :haul,
        :operator,
        Keyword.merge(original_operator || [], slug: result.company.slug)
      )

      on_exit(fn ->
        Application.put_env(:haul, :operator, original_operator)
      end)

      # GET / should now render operator content
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ "555-SITE"
      assert html =~ "render@example.com"
      assert html =~ "Denver, CO"

      # Services should be visible
      assert html =~ "What We Do"
    end
  end

  describe "signup form has sign-in link" do
    test "links to /app/login", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/signup")

      assert html =~ "Already have an account?"
      assert html =~ "/app/login"
    end
  end
end
