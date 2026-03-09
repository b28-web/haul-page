defmodule HaulWeb.MarketingPageTest do
  use HaulWeb.ConnCase, async: true

  # Set host to bare platform domain (haulpage.test = base_domain in test config)
  # so TenantResolver identifies this as the platform host and serves the marketing page.
  setup %{conn: conn} do
    %{conn: %{conn | host: "haulpage.test"}}
  end

  test "GET / on bare domain returns marketing page", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    assert body =~ "Your Hauling Business Online in 2 Minutes"
  end

  test "marketing page contains pricing tiers", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    assert body =~ "Starter"
    assert body =~ "Free"
    assert body =~ "Pro"
    assert body =~ "$29"
    assert body =~ "Business"
    assert body =~ "$79"
    assert body =~ "Dedicated"
    assert body =~ "$149"
  end

  test "marketing page contains feature descriptions", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    assert body =~ "Professional Website"
    assert body =~ "Online Booking"
    assert body =~ "SMS Alerts"
    assert body =~ "Print Flyers"
    assert body =~ "QR Codes"
    assert body =~ "Mobile Ready"
  end

  test "marketing page has CTA links to signup", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    assert body =~ "/app/signup"
    assert body =~ "Get Started Free"
    assert body =~ "Start Free"
  end

  test "marketing page has how-it-works section", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    assert body =~ "How It Works"
    assert body =~ "Sign Up"
    assert body =~ "Customize"
    assert body =~ "Get Customers"
  end

  test "marketing page does not contain operator-specific content", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    refute body =~ "Junk Hauling"
    refute body =~ "What We Do"
    refute body =~ "Why Hire Us"
  end

  test "marketing page sets correct page title", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)

    assert body =~ "Your hauling business online in 2 minutes"
  end
end
