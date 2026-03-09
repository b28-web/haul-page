defmodule HaulWeb.AdminAuthHooks do
  @moduledoc """
  LiveView on_mount hooks for superadmin authentication.
  Returns 404 (not redirect) when unauthenticated to avoid revealing route existence.
  """
  import Phoenix.LiveView

  alias Haul.Admin.AdminUser
  alias AshAuthentication.Jwt

  @doc """
  Requires an authenticated admin user.
  Returns 404 if not authenticated.
  """
  def on_mount(:require_admin, _params, session, socket) do
    case load_admin_from_session(session) do
      {:ok, admin} ->
        {:cont, Phoenix.Component.assign(socket, :current_admin, admin)}

      :error ->
        {:halt, socket |> redirect(to: "/")}
    end
  end

  defp load_admin_from_session(%{"_admin_user_token" => token}) when is_binary(token) do
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

  defp load_admin_from_session(_), do: :error
end
