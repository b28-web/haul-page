defmodule HaulWeb.AppSessionController do
  @moduledoc """
  Handles session creation (login) and deletion (logout) for the /app admin area.
  """
  use HaulWeb, :controller

  def create(conn, %{"session" => %{"token" => token, "tenant" => tenant}}) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:tenant, tenant)
    |> configure_session(renew: true)
    |> redirect(to: ~p"/app")
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/app/login")
  end
end
