defmodule HaulWeb.DebugControllerTest do
  use HaulWeb.ConnCase, async: true

  describe "GET /dev/sentry-test" do
    test "raises a test error to verify Sentry integration", %{conn: conn} do
      assert_raise RuntimeError, ~r/Sentry test error/, fn ->
        get(conn, "/dev/sentry-test")
      end
    end
  end
end
