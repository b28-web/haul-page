defmodule HaulWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use HaulWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint HaulWeb.Endpoint

      use HaulWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import HaulWeb.ConnCase
    end
  end

  setup tags do
    Haul.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Creates a company, provisions tenant, registers a user, and returns auth context.
  """
  def create_authenticated_context(attrs \\ %{}) do
    alias Haul.Accounts.Changes.ProvisionTenant
    alias Haul.Accounts.Company
    alias Haul.Accounts.User

    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Test Co"})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    user_attrs = %{
      email: attrs[:email] || "admin@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    }

    {:ok, user} =
      User
      |> Ash.Changeset.for_create(:register_with_password, user_attrs,
        tenant: tenant,
        authorize?: false
      )
      |> Ash.create()

    role = attrs[:role] || :owner

    {:ok, user} =
      user
      |> Ash.Changeset.for_update(:update_user, %{role: role},
        tenant: tenant,
        authorize?: false
      )
      |> Ash.update()

    # Sign in to get a token
    {:ok, signed_in} =
      User
      |> Ash.Query.for_read(
        :sign_in_with_password,
        %{email: user_attrs.email, password: user_attrs.password},
        tenant: tenant
      )
      |> Ash.read_one()

    token = signed_in.__metadata__.token

    %{company: company, tenant: tenant, user: user, token: token}
  end

  @doc """
  Sets up a conn with authentication session.
  """
  def log_in_user(conn, %{token: token, tenant: tenant}) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{user_token: token, tenant: tenant})
  end

  @doc """
  Cleanup helper for tenant schemas created during tests.
  """
  def cleanup_tenants do
    {:ok, result} =
      Ecto.Adapters.SQL.query(Haul.Repo, """
      SELECT schema_name FROM information_schema.schemata
      WHERE schema_name LIKE 'tenant_%'
      """)

    for [schema] <- result.rows do
      Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
    end
  end
end
