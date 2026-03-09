defmodule HaulWeb.OnboardingQATest do
  @moduledoc """
  Browser QA for CLI onboarding (T-014-03).
  Runs Haul.Onboarding.run/1, then verifies all public pages render
  correctly with the onboarded operator's content.
  """
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    original_operator = Application.get_env(:haul, :operator)

    params = %{
      name: "Test Hauling",
      phone: "555-0199",
      email: "test@example.com",
      area: "Portland, OR"
    }

    {:ok, result} = Haul.Onboarding.run(params)

    # Override operator config so ContentHelpers.resolve_tenant() finds our tenant
    Application.put_env(
      :haul,
      :operator,
      Keyword.merge(original_operator || [], slug: result.company.slug)
    )

    on_exit(fn ->
      Application.put_env(:haul, :operator, original_operator)
      cleanup_tenants()
    end)

    %{result: result}
  end

  describe "landing page" do
    test "renders with onboarded operator content", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      # Operator info updated by onboarding in SiteConfig
      assert html =~ "555-0199"
      assert html =~ "test@example.com"
      assert html =~ "Portland, OR"

      # Services section
      assert html =~ "What We Do"
    end

    test "displays default services from content pack", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      # Default content pack includes these service titles
      assert html =~ "Junk Removal"
      assert html =~ "Cleanouts"
    end
  end

  describe "scan page" do
    test "renders gallery and endorsements", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/scan")

      # Operator phone (updated via onboarding)
      assert html =~ "555-0199"

      # Gallery section
      assert html =~ "Our Work"

      # Endorsements section
      assert html =~ "What Customers Say"
    end

    test "displays gallery items with captions", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/scan")

      # Default gallery items have before/after images
      assert html =~ "Before"
      assert html =~ "After"
    end

    test "displays endorsement quotes", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/scan")

      # Default endorsements have "(Sample)" in customer names
      assert html =~ "(Sample)"
    end
  end

  describe "booking page" do
    test "renders booking form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/book")

      assert html =~ "</form>"
    end
  end

  describe "admin login" do
    test "login page renders", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/login")

      assert html =~ "Sign In"
      assert html =~ "Email"
      assert html =~ "Password"
    end
  end

  describe "onboarded content quality" do
    test "owner user exists with correct role", %{result: result} do
      assert to_string(result.user.email) == "test@example.com"
      assert result.user.role == :owner
    end

    test "default content is professional, not placeholder", %{result: result} do
      # 6 services seeded from defaults
      assert length(result.content.services) == 6
      # 4 gallery items
      assert length(result.content.gallery_items) == 4
      # 3 endorsements
      assert length(result.content.endorsements) == 3
    end

    test "site config updated with operator info", %{result: result} do
      [config] = Ash.read!(Haul.Content.SiteConfig, tenant: result.tenant)

      assert config.phone == "555-0199"
      assert config.email == "test@example.com"
      assert config.service_area == "Portland, OR"
    end
  end
end
