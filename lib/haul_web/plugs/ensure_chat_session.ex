defmodule HaulWeb.Plugs.EnsureChatSession do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "chat_session_id") do
      nil ->
        session_id = Ecto.UUID.generate()
        put_session(conn, "chat_session_id", session_id)

      _existing ->
        conn
    end
  end
end
