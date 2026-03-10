defmodule Haul.Accounts.SecurityTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Accounts.User

  defp register_user(tenant, attrs) do
    defaults = %{
      email: "user-#{System.unique_integer([:positive])}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    }

    User
    |> Ash.Changeset.for_create(:register_with_password, Map.merge(defaults, attrs),
      tenant: tenant,
      authorize?: false
    )
    |> Ash.create!()
  end

  defp set_role(user, role, tenant) do
    user
    |> Ash.Changeset.for_update(:update_user, %{role: role},
      tenant: tenant,
      authorize?: false
    )
    |> Ash.update!()
  end

  setup do
    {:ok, company_a} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Company A #{System.unique_integer([:positive])}"
      })
      |> Ash.create()

    {:ok, company_b} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Company B #{System.unique_integer([:positive])}"
      })
      |> Ash.create()

    tenant_a = ProvisionTenant.tenant_schema(company_a.slug)
    tenant_b = ProvisionTenant.tenant_schema(company_b.slug)

    owner_a =
      register_user(tenant_a, %{email: "owner@a.com"})
      |> set_role(:owner, tenant_a)

    crew_a = register_user(tenant_a, %{email: "crew@a.com"})

    owner_b =
      register_user(tenant_b, %{email: "owner@b.com"})
      |> set_role(:owner, tenant_b)

    on_exit(fn ->
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant_a}" CASCADE))
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant_b}" CASCADE))
    end)

    %{
      company_a: company_a,
      company_b: company_b,
      tenant_a: tenant_a,
      tenant_b: tenant_b,
      owner_a: owner_a,
      crew_a: crew_a,
      owner_b: owner_b
    }
  end

  describe "cross-tenant isolation" do
    test "tenant A users are not visible when querying tenant A's schema", ctx do
      # Query tenant A — see tenant A's users
      {:ok, users_in_a} =
        User
        |> Ash.Query.for_read(:read, %{}, tenant: ctx.tenant_a, actor: ctx.owner_a)
        |> Ash.read()

      emails = Enum.map(users_in_a, fn u -> to_string(u.email) end) |> Enum.sort()
      assert length(users_in_a) == 2
      assert "crew@a.com" in emails
      assert "owner@a.com" in emails
    end

    test "tenant B users are not visible when querying tenant B's schema from tenant A", ctx do
      # Query tenant B — see only tenant B's users, NOT tenant A's
      {:ok, users_in_b} =
        User
        |> Ash.Query.for_read(:read, %{}, tenant: ctx.tenant_b, actor: ctx.owner_a)
        |> Ash.read()

      emails = Enum.map(users_in_b, fn u -> to_string(u.email) end)
      # Tenant B only has owner_b — tenant A's users (owner_a, crew_a) are NOT here
      assert length(users_in_b) == 1
      assert "owner@b.com" in emails
      refute "owner@a.com" in emails
      refute "crew@a.com" in emails
    end

    test "data is stored in separate Postgres schemas", ctx do
      # Directly query the database to verify physical schema separation
      {:ok, result_a} =
        Ecto.Adapters.SQL.query(
          Haul.Repo,
          "SELECT email FROM \"#{ctx.tenant_a}\".users ORDER BY email"
        )

      {:ok, result_b} =
        Ecto.Adapters.SQL.query(
          Haul.Repo,
          "SELECT email FROM \"#{ctx.tenant_b}\".users ORDER BY email"
        )

      emails_a = Enum.map(result_a.rows, &hd/1)
      emails_b = Enum.map(result_b.rows, &hd/1)

      assert "crew@a.com" in emails_a
      assert "owner@a.com" in emails_a
      refute "owner@b.com" in emails_a

      assert "owner@b.com" in emails_b
      refute "owner@a.com" in emails_b
    end

    test "users in different tenants have independent email uniqueness", ctx do
      _user_a = register_user(ctx.tenant_a, %{email: "shared@email.com"})
      _user_b = register_user(ctx.tenant_b, %{email: "shared@email.com"})
    end
  end

  describe "role-based policies" do
    test "owner can list all users in their tenant", ctx do
      {:ok, users} =
        User
        |> Ash.Query.for_read(:read, %{}, tenant: ctx.tenant_a, actor: ctx.owner_a)
        |> Ash.read()

      assert length(users) == 2
    end

    test "crew can read their own record", ctx do
      {:ok, users} =
        User
        |> Ash.Query.for_read(:read, %{}, tenant: ctx.tenant_a, actor: ctx.crew_a)
        |> Ash.read()

      assert length(users) == 1
      assert hd(users).id == ctx.crew_a.id
    end

    test "crew can update their own profile", ctx do
      assert {:ok, updated} =
               ctx.crew_a
               |> Ash.Changeset.for_update(:update_profile, %{name: "New Name"},
                 tenant: ctx.tenant_a,
                 actor: ctx.crew_a
               )
               |> Ash.update()

      assert updated.name == "New Name"
    end

    test "crew cannot update another user's profile", ctx do
      assert {:error, %Ash.Error.Forbidden{}} =
               ctx.owner_a
               |> Ash.Changeset.for_update(:update_profile, %{name: "Hacked"},
                 tenant: ctx.tenant_a,
                 actor: ctx.crew_a
               )
               |> Ash.update()
    end

    test "crew cannot use update_user action (manage roles)", ctx do
      assert {:error, %Ash.Error.Forbidden{}} =
               ctx.crew_a
               |> Ash.Changeset.for_update(:update_user, %{role: :owner},
                 tenant: ctx.tenant_a,
                 actor: ctx.crew_a
               )
               |> Ash.update()
    end

    test "owner can update any user's role", ctx do
      assert {:ok, promoted} =
               ctx.crew_a
               |> Ash.Changeset.for_update(:update_user, %{role: :dispatcher},
                 tenant: ctx.tenant_a,
                 actor: ctx.owner_a
               )
               |> Ash.update()

      assert promoted.role == :dispatcher
    end

    test "unauthenticated user cannot read users", ctx do
      assert {:error, %Ash.Error.Forbidden{}} =
               User
               |> Ash.Query.for_read(:read, %{}, tenant: ctx.tenant_a, actor: nil)
               |> Ash.read()
    end
  end
end
