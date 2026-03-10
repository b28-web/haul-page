defmodule HaulWeb.App.SignupLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    clear_rate_limits()
    :ok
  end

  defp conn_with_ip(conn, ip \\ nil) do
    ip = ip || "10.0.0.#{System.unique_integer([:positive, :monotonic])}"
    Phoenix.ConnTest.init_test_session(conn, %{"remote_ip" => ip})
  end

  describe "signup page" do
    test "renders signup form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/signup")

      assert html =~ "Get Your Hauling Site Live"
      assert html =~ "Business Name"
      assert html =~ "Email"
      assert html =~ "Password"
      assert html =~ "Create My Site"
    end

    test "shows slug preview on business name input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form", signup: %{name: "Joe's Hauling"})
        |> render_change()

      assert html =~ "joe-s-hauling"
      assert html =~ "Your site:"
    end

    test "shows slug availability", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form", signup: %{name: "Fresh New Biz"})
        |> render_change()

      assert html =~ "Available"
    end

    test "shows slug taken for existing company", %{conn: conn} do
      ctx = create_authenticated_context()
      on_exit(fn -> cleanup_tenant(ctx.tenant) end)

      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form", signup: %{name: ctx.company.name})
        |> render_change()

      assert html =~ "Taken"
    end

    test "shows validation error for missing required fields", %{conn: conn} do
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

    test "shows error for short password", %{conn: conn} do
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

    test "shows error for password mismatch", %{conn: conn} do
      conn = conn_with_ip(conn)
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form",
          signup: %{
            name: "Test Biz",
            email: "test@example.com",
            password: "Password123!",
            password_confirmation: "Different123!"
          }
        )
        |> render_submit()

      assert html =~ "passwords do not match"
    end

    test "successful signup triggers form submission", %{conn: conn} do
      on_exit(fn -> cleanup_tenant("tenant_signup-test-co") end)
      conn = conn_with_ip(conn)
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form",
          signup: %{
            name: "Signup Test Co",
            email: "signup@example.com",
            phone: "555-9999",
            area: "Portland, OR",
            password: "Password123!",
            password_confirmation: "Password123!"
          }
        )
        |> render_submit()

      # phx-trigger-action should be set — the form will POST to /app/session
      assert html =~ "phx-trigger-action"
    end

    test "rate limiting blocks excessive signups", %{conn: conn} do
      on_exit(fn ->
        for i <- 1..5, do: cleanup_tenant("tenant_rate-test-#{i}")
      end)

      ip = "10.99.99.#{:rand.uniform(255)}"
      conn = conn_with_ip(conn, ip)

      # Exhaust the rate limit
      for i <- 1..5 do
        {:ok, view, _html} = live(conn, "/app/signup")

        view
        |> form("form",
          signup: %{
            name: "Rate Test #{i}",
            email: "rate#{i}@example.com",
            password: "Password123!",
            password_confirmation: "Password123!"
          }
        )
        |> render_submit()
      end

      # 6th attempt should be blocked
      {:ok, view, _html} = live(conn, "/app/signup")

      html =
        view
        |> form("form",
          signup: %{
            name: "Rate Test 6",
            email: "rate6@example.com",
            password: "Password123!",
            password_confirmation: "Password123!"
          }
        )
        |> render_submit()

      assert html =~ "Too many signup attempts"
    end

    test "has sign in link", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/signup")

      assert html =~ "Already have an account?"
      assert html =~ "/app/login"
    end

    test "has link to AI chat assistant", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/signup")

      assert html =~ "try our AI assistant"
      assert html =~ "/start"
    end
  end
end
