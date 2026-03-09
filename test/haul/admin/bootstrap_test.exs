defmodule Haul.Admin.BootstrapTest do
  use Haul.DataCase, async: true

  alias Haul.Admin.AdminUser
  alias Haul.Admin.Bootstrap

  require Ash.Query

  describe "ensure_admin!/0" do
    test "creates admin user when ADMIN_EMAIL is set and no admin exists" do
      System.put_env("ADMIN_EMAIL", "superadmin@test.com")
      on_exit(fn -> System.delete_env("ADMIN_EMAIL") end)

      assert :ok = Bootstrap.ensure_admin!()

      assert {:ok, admin} =
               AdminUser
               |> Ash.Query.filter(email == "superadmin@test.com")
               |> Ash.read_one(authorize?: false)

      assert admin.email.string == "superadmin@test.com"
      assert admin.setup_completed == false
      assert admin.setup_token_hash != nil
      assert admin.hashed_password == nil
    end

    test "returns :noop when ADMIN_EMAIL is not set" do
      System.delete_env("ADMIN_EMAIL")
      assert :noop = Bootstrap.ensure_admin!()
    end

    test "returns :noop when ADMIN_EMAIL is empty" do
      System.put_env("ADMIN_EMAIL", "")
      on_exit(fn -> System.delete_env("ADMIN_EMAIL") end)

      assert :noop = Bootstrap.ensure_admin!()
    end

    test "is idempotent — does not create duplicate admin" do
      System.put_env("ADMIN_EMAIL", "idempotent@test.com")
      on_exit(fn -> System.delete_env("ADMIN_EMAIL") end)

      assert :ok = Bootstrap.ensure_admin!()
      assert :noop = Bootstrap.ensure_admin!()

      assert {:ok, admins} =
               AdminUser
               |> Ash.Query.filter(email == "idempotent@test.com")
               |> Ash.read(authorize?: false)

      assert length(admins) == 1
    end
  end
end
