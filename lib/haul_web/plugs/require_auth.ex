defmodule HaulWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug that requires an authenticated user with owner or dispatcher role.
  Redirects to /app/login if not authenticated or unauthorized.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Haul.Accounts.User
  alias AshAuthentication.Jwt

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with token when is_binary(token) <- get_session(conn, :user_token),
         tenant when is_binary(tenant) <- get_session(conn, :tenant),
         {:ok, %{"sub" => subject}, _} <- Jwt.verify(token, User),
         {:ok, user} <- AshAuthentication.subject_to_user(subject, User, tenant: tenant),
         true <- user.role in [:owner, :dispatcher] do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> redirect(to: "/app/login")
        |> halt()
    end
  end
end
