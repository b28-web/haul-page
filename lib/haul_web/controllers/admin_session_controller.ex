defmodule HaulWeb.AdminSessionController do
  @moduledoc """
  Handles session creation and deletion for the /admin superadmin area.
  """
  use HaulWeb, :controller

  def create(conn, %{"session" => %{"token" => token}}) do
    conn
    |> put_session(:_admin_user_token, token)
    |> configure_session(renew: true)
    |> redirect(to: ~p"/admin")
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:_admin_user_token)
    |> redirect(to: ~p"/admin/login")
  end
end
