defmodule HaulWeb.DebugControllerTest do
  use HaulWeb.ConnCase, async: true

  describe "GET /dev/sentry-test" do
    test "is not accessible in test environment", %{conn: conn} do
      conn = get(conn, "/dev/sentry-test")
      assert conn.status == 404
    end
  end
end
