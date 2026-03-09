defmodule HaulWeb.App.DashboardLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    on_exit(fn -> cleanup_tenants() end)
    :ok
  end

  describe "unauthenticated" do
    test "redirects to /app/login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app")
    end
  end

  describe "authenticated owner" do
    setup %{conn: conn} do
      ctx = create_authenticated_context(role: :owner)
      conn = log_in_user(conn, ctx)
      %{conn: conn, ctx: ctx}
    end

    test "renders welcome message", %{conn: conn, ctx: ctx} do
      {:ok, _view, html} = live(conn, "/app")

      assert html =~ "Dashboard"
      assert html =~ "Welcome,"
      assert html =~ to_string(ctx.user.email)
    end

    test "shows sidebar navigation", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app")

      assert html =~ "Dashboard"
      assert html =~ "Content"
      assert html =~ "Bookings"
      assert html =~ "Settings"
    end

    test "shows company name in header", %{conn: conn, ctx: ctx} do
      {:ok, _view, html} = live(conn, "/app")

      assert html =~ ctx.company.name
    end

    test "shows sign out link", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app")

      assert html =~ "Sign out"
    end
  end

  describe "authenticated dispatcher" do
    setup %{conn: conn} do
      ctx = create_authenticated_context(role: :dispatcher, email: "dispatcher@example.com")
      conn = log_in_user(conn, ctx)
      %{conn: conn, ctx: ctx}
    end

    test "can access dashboard", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/app")

      assert html =~ "Dashboard"
      assert html =~ "Welcome,"
    end
  end

  describe "crew role" do
    setup %{conn: conn} do
      ctx = create_authenticated_context(role: :crew, email: "crew@example.com")
      conn = log_in_user(conn, ctx)
      %{conn: conn}
    end

    test "redirects to /app/login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/app/login"}}} = live(conn, "/app")
    end
  end
end
