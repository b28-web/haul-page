defmodule HaulWeb.AuthHooks do
  @moduledoc """
  LiveView on_mount hooks for authentication.
  Supports impersonation bypass for superadmin.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  alias Haul.Accounts.User
  alias AshAuthentication.Jwt
  alias HaulWeb.Impersonation

  require Ash.Query

  @doc """
  Requires an authenticated user with owner or dispatcher role.
  Redirects to /app/login if not authenticated or unauthorized.
  During impersonation, bypasses user auth and uses admin session.
  """
  def on_mount(:require_auth, _params, session, socket) do
    case check_impersonation(session) do
      {:impersonating, admin, company, remaining} ->
        {:cont,
         socket
         |> assign(:current_user, nil)
         |> assign(:current_company, company)
         |> assign(:current_admin, admin)
         |> assign(:impersonating, true)
         |> assign(:impersonating_slug, company.slug)
         |> assign(:impersonating_remaining, remaining)
         |> assign(:current_path, "/app")
         |> attach_hook(:set_current_path, :handle_params, fn _params, uri, socket ->
           path = URI.parse(uri).path
           {:cont, assign(socket, :current_path, path)}
         end)}

      :expired ->
        {:halt,
         socket
         |> put_flash(:error, "Impersonation session expired")
         |> redirect(to: "/admin")}

      :not_impersonating ->
        handle_normal_auth(session, socket)
    end
  end

  defp check_impersonation(session) do
    case Impersonation.validate_and_load(session) do
      {:ok, admin, company} ->
        remaining = Impersonation.remaining_minutes(session)
        {:impersonating, admin, company, remaining}

      {:expired, _admin_id} ->
        :expired

      :not_impersonating ->
        :not_impersonating
    end
  end

  defp handle_normal_auth(session, socket) do
    case load_user_from_session(session) do
      {:ok, user, company} when user.role in [:owner, :dispatcher] ->
        {:cont,
         socket
         |> assign(:current_user, user)
         |> assign(:current_company, company)
         |> assign(:impersonating, false)
         |> assign(:current_path, "/app")
         |> attach_hook(:set_current_path, :handle_params, fn _params, uri, socket ->
           path = URI.parse(uri).path
           {:cont, assign(socket, :current_path, path)}
         end)}

      {:ok, _user, _company} ->
        {:halt, socket |> redirect(to: "/app/login")}

      :error ->
        {:halt, socket |> redirect(to: "/app/login")}
    end
  end

  defp load_user_from_session(%{"user_token" => token, "tenant" => tenant} = _session) do
    case Jwt.verify(token, User, tenant: tenant) do
      {:ok, %{"sub" => subject}, _} ->
        case AshAuthentication.subject_to_user(subject, User, tenant: tenant) do
          {:ok, user} ->
            company = load_company(tenant)
            {:ok, user, company}

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  defp load_user_from_session(_), do: :error

  defp load_company(tenant) do
    slug = String.replace_prefix(tenant, "tenant_", "")

    Haul.Accounts.Company
    |> Ash.Query.filter(slug == ^slug)
    |> Ash.read_one()
    |> case do
      {:ok, company} -> company
      _ -> nil
    end
  end
end
