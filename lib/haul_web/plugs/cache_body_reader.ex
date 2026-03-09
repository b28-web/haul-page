defmodule HaulWeb.Plugs.CacheBodyReader do
  @moduledoc """
  Custom body reader that caches the raw request body in `conn.assigns[:raw_body]`.

  Used by `Plug.Parsers` via the `body_reader` option so that webhook endpoints
  can access the unparsed body for signature verification.
  """

  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        conn = update_in(conn.assigns[:raw_body], &((&1 || "") <> body))
        {:ok, body, conn}

      {:more, body, conn} ->
        conn = update_in(conn.assigns[:raw_body], &((&1 || "") <> body))
        {:more, body, conn}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
