defmodule HaulWeb.App.LoginLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    on_exit(fn -> cleanup_tenants() end)
    :ok
  end

  describe "login page" do
    test "renders login form", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app/login")

      assert html =~ "Sign In"
      assert html =~ "Email"
      assert html =~ "Password"
    end

    test "shows error on invalid credentials", %{conn: conn} do
      ctx = create_authenticated_context()

      # Put tenant in session so login can resolve it
      conn = Phoenix.ConnTest.init_test_session(conn, %{tenant: ctx.tenant})

      {:ok, view, _html} = live(conn, "/app/login")

      view
      |> form("form", session: %{email: "wrong@example.com", password: "WrongPass123!"})
      |> render_submit()

      assert render(view) =~ "Invalid email or password"
    end
  end
end
