defmodule Haul.Accounts.UserTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Accounts.User

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Test Co"})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    on_exit(fn ->
      {:ok, result} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- result.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    %{company: company, tenant: tenant}
  end

  defp register_user(tenant, attrs \\ %{}) do
    defaults = %{
      email: "test-#{System.unique_integer([:positive])}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    }

    User
    |> Ash.Changeset.for_create(:register_with_password, Map.merge(defaults, attrs),
      tenant: tenant,
      authorize?: false
    )
    |> Ash.create()
  end

  describe "registration" do
    test "registers a user with password", ctx do
      assert {:ok, user} = register_user(ctx.tenant, %{email: "test@example.com"})

      assert to_string(user.email) == "test@example.com"
      assert user.role == :crew
      assert user.active == true
      assert user.hashed_password != nil
    end

    test "rejects registration with mismatched password confirmation", ctx do
      assert {:error, _} =
               register_user(ctx.tenant, %{
                 email: "test@example.com",
                 password: "Password123!",
                 password_confirmation: "Different456!"
               })
    end

    test "rejects duplicate email within same tenant", ctx do
      {:ok, _} = register_user(ctx.tenant, %{email: "dupe@example.com"})

      assert {:error, _} = register_user(ctx.tenant, %{email: "dupe@example.com"})
    end
  end

  describe "sign in" do
    test "signs in with correct password", ctx do
      {:ok, _user} = register_user(ctx.tenant, %{email: "login@example.com"})

      assert {:ok, signed_in} =
               User
               |> Ash.Query.for_read(
                 :sign_in_with_password,
                 %{email: "login@example.com", password: "Password123!"},
                 tenant: ctx.tenant
               )
               |> Ash.read_one()

      assert to_string(signed_in.email) == "login@example.com"
    end

    test "rejects sign in with wrong password", ctx do
      {:ok, _user} = register_user(ctx.tenant, %{email: "login2@example.com"})

      assert {:error, _} =
               User
               |> Ash.Query.for_read(
                 :sign_in_with_password,
                 %{email: "login2@example.com", password: "WrongPass456!"},
                 tenant: ctx.tenant
               )
               |> Ash.read_one()
    end
  end

  describe "role defaults" do
    test "new user defaults to crew role", ctx do
      {:ok, user} = register_user(ctx.tenant)
      assert user.role == :crew
    end
  end
end
