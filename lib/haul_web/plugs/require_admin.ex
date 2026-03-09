defmodule HaulWeb.Plugs.RequireAdmin do
  @moduledoc """
  Plug that returns 404 if the request is not from an authenticated admin user.
  Used in the admin pipeline to hide admin routes from non-admins.
  Also blocks admin access during impersonation (no privilege stacking).
  """
  import Plug.Conn

  alias Haul.Admin.AdminUser
  alias AshAuthentication.Jwt

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :_admin_user_token) do
      token when is_binary(token) ->
        case verify_admin(token) do
          {:ok, admin} ->
            if get_session(conn, "impersonating_slug") do
              send_404(conn)
            else
              assign(conn, :current_admin, admin)
            end

          :error ->
            send_404(conn)
        end

      _ ->
        send_404(conn)
    end
  end

  defp verify_admin(token) do
    case Jwt.verify(token, AdminUser) do
      {:ok, %{"sub" => subject}, _} ->
        case AshAuthentication.subject_to_user(subject, AdminUser) do
          {:ok, %AdminUser{setup_completed: true} = admin} -> {:ok, admin}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp send_404(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(404, "Not Found")
    |> halt()
  end
end
