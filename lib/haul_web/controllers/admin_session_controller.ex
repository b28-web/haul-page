defmodule HaulWeb.AdminSessionController do
  @moduledoc """
  Handles session creation, deletion, and impersonation for the /admin superadmin area.
  """
  use HaulWeb, :controller

  alias Haul.Accounts.Company
  alias HaulWeb.Impersonation

  require Ash.Query

  def create(conn, %{"session" => %{"token" => token}}) do
    conn
    |> put_session(:_admin_user_token, token)
    |> configure_session(renew: true)
    |> redirect(to: ~p"/admin")
  end

  def delete(conn, _params) do
    conn
    |> Impersonation.end_session(:manual)
    |> delete_session(:_admin_user_token)
    |> redirect(to: ~p"/admin/login")
  end

  def impersonate(conn, %{"slug" => slug}) do
    admin = conn.assigns.current_admin

    case load_company(slug) do
      {:ok, company} ->
        schema_name = "tenant_#{company.slug}"

        if schema_exists?(schema_name) do
          conn
          |> Impersonation.start_session(admin, company.slug)
          |> redirect(to: ~p"/app")
        else
          conn
          |> put_flash(:error, "Cannot impersonate: tenant not provisioned")
          |> redirect(to: ~p"/admin/accounts/#{slug}")
        end

      :error ->
        conn
        |> put_flash(:error, "Account not found")
        |> redirect(to: ~p"/admin/accounts")
    end
  end

  def exit_impersonation(conn, _params) do
    # This route is in the public /admin scope (no RequireAdmin plug).
    # Validate admin session manually.
    session = get_session(conn)

    case Impersonation.check_admin_session(session) do
      {:ok, _admin} ->
        conn
        |> Impersonation.end_session(:manual)
        |> redirect(to: ~p"/admin/accounts")

      :error ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "Not Found")
        |> halt()
    end
  end

  defp load_company(slug) do
    Company
    |> Ash.Query.filter(slug == ^slug)
    |> Ash.read_one()
    |> case do
      {:ok, %Company{} = company} -> {:ok, company}
      _ -> :error
    end
  end

  defp schema_exists?(schema_name) do
    case Ecto.Adapters.SQL.query(
           Haul.Repo,
           "SELECT 1 FROM information_schema.schemata WHERE schema_name = $1",
           [schema_name]
         ) do
      {:ok, %{num_rows: n}} when n > 0 -> true
      _ -> false
    end
  end
end
