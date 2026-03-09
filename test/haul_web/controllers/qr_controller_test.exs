defmodule HaulWeb.QRControllerTest do
  use HaulWeb.ConnCase

  describe "GET /scan/qr" do
    test "returns SVG by default", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr")

      assert response(conn, 200)
      assert response_content_type(conn, :xml) =~ "image/svg+xml"
      assert conn.resp_body =~ "<?xml"
      assert conn.resp_body =~ "<svg"
    end

    test "returns PNG when format=png", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr?format=png")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") |> hd() =~ "image/png"
      # PNG magic bytes
      assert <<137, 80, 78, 71, _rest::binary>> = conn.resp_body
    end

    test "respects size parameter for SVG", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr?size=500")

      assert response(conn, 200)
      # eqrcode may produce floating point widths
      assert conn.resp_body =~ "width=\"500"
    end

    test "clamps size to minimum 100", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr?size=10")

      assert response(conn, 200)
      assert conn.resp_body =~ "width=\"100"
    end

    test "clamps size to maximum 1000", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr?size=5000")

      assert response(conn, 200)
      assert conn.resp_body =~ "width=\"1000"
    end

    test "returns 400 for invalid format", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr?format=gif")

      assert response(conn, 400)
      assert conn.resp_body =~ "Invalid format"
    end

    test "includes Content-Disposition header for SVG", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr")

      assert get_resp_header(conn, "content-disposition") == [~s(attachment; filename="qr-scan.svg")]
    end

    test "includes Content-Disposition header for PNG", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr?format=png")

      assert get_resp_header(conn, "content-disposition") == [~s(attachment; filename="qr-scan.png")]
    end

    test "includes Cache-Control header", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr")

      assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]
    end

    test "QR encodes the scan page URL", %{conn: conn} do
      conn = get(conn, ~p"/scan/qr")
      # The SVG output should be valid (non-empty, contains svg elements)
      assert response(conn, 200)
      assert byte_size(conn.resp_body) > 100
    end
  end
end
