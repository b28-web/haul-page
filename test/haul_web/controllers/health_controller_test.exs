defmodule HaulWeb.HealthControllerTest do
  use HaulWeb.ConnCase, async: true

  test "GET /healthz returns 200 ok", %{conn: conn} do
    conn = get(conn, "/healthz")
    assert response(conn, 200) == "ok"
    assert response_content_type(conn, :text) =~ "text/plain"
  end
end
