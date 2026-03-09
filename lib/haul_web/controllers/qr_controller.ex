defmodule HaulWeb.QRController do
  use HaulWeb, :controller

  @min_size 100
  @max_size 1000
  @default_size 300

  def generate(conn, params) do
    format = params["format"] || "svg"
    size = parse_size(params["size"])

    if format in ~w(svg png) do
      url = HaulWeb.Endpoint.url() <> "/scan"
      matrix = EQRCode.encode(url)

      conn
      |> put_resp_header("cache-control", "public, max-age=86400")
      |> send_qr(matrix, format, size)
    else
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(400, "Invalid format. Use \"svg\" or \"png\".")
    end
  end

  defp send_qr(conn, matrix, "svg", size) do
    svg = EQRCode.svg(matrix, width: size)

    conn
    |> put_resp_content_type("image/svg+xml")
    |> put_resp_header("content-disposition", ~s(attachment; filename="qr-scan.svg"))
    |> send_resp(200, svg)
  end

  defp send_qr(conn, matrix, "png", size) do
    png = EQRCode.png(matrix, width: size)

    conn
    |> put_resp_content_type("image/png")
    |> put_resp_header("content-disposition", ~s(attachment; filename="qr-scan.png"))
    |> send_resp(200, png)
  end

  defp parse_size(nil), do: @default_size

  defp parse_size(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, ""} -> clamp(n, @min_size, @max_size)
      _ -> @default_size
    end
  end

  defp clamp(n, min, _max) when n < min, do: min
  defp clamp(n, _min, max) when n > max, do: max
  defp clamp(n, _min, _max), do: n
end
