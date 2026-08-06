defmodule HaulWeb.DevSessionController do
  @moduledoc """
  Dev-only controller for quick sign-in to a premade dev account.
  Compiled only when `config :haul, dev_routes: true`.
  """
  use HaulWeb, :controller

  require Ash.Query

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Onboarding

  @dev_params %{
    name: "Dev Operator",
    email: "dev@haulpage.com",
    password: "password123!",
    password_confirmation: "password123!",
    phone: "555-0100",
    area: "Springfield"
  }

  def login(conn, _params) do
    case ensure_dev_account() do
      {:ok, %{user: user, tenant: tenant}} ->
        token = user.__metadata__.token

        conn
        |> put_session(:user_token, token)
        |> put_session(:tenant, tenant)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/app")

      {:error, step, reason} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(500, "Dev login failed at #{step}: #{inspect(reason)}")
    end
  end

  defp ensure_dev_account do
    slug = Onboarding.derive_slug(@dev_params.name)
    tenant = ProvisionTenant.tenant_schema(slug)

    # Try signing in first (account already exists)
    case sign_in_existing(tenant, @dev_params.email, @dev_params.password) do
      {:ok, user} ->
        {:ok, %{user: user, tenant: tenant}}

      _ ->
        # First time — create via signup
        Onboarding.signup(@dev_params)
    end
  end

  defp sign_in_existing(tenant, email, password) do
    Haul.Accounts.User
    |> Ash.Query.for_read(:sign_in_with_password, %{email: email, password: password},
      tenant: tenant,
      authorize?: false
    )
    |> Ash.read_one()
  end
end
