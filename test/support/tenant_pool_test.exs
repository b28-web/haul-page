defmodule Haul.Test.TenantPoolTest do
  use Haul.DataCase, async: false

  alias Haul.Test.TenantPool

  describe "checkout/1" do
    test "returns context with expected keys for each group" do
      for group <- TenantPool.groups() do
        ctx = TenantPool.checkout(group)
        assert %{company: _, tenant: _, user: _, token: _} = ctx
        assert is_binary(ctx.tenant)
        assert String.starts_with?(ctx.tenant, "tenant___pool_")
      end
    end

    test "returns different tenants for different groups" do
      groups = TenantPool.groups()
      tenants = Enum.map(groups, fn g -> TenantPool.checkout(g).tenant end)
      assert length(Enum.uniq(tenants)) == length(tenants)
    end

    test "raises for unknown group" do
      assert_raise RuntimeError, ~r/Unknown pool group/, fn ->
        TenantPool.checkout(:nonexistent)
      end
    end
  end

  describe "pool tenants are functional" do
    test "can create a resource in a pool tenant" do
      ctx = TenantPool.checkout(:pool_a)

      service = Haul.Test.Factories.build_service(ctx.tenant, %{title: "Pool Test Service"})
      assert service.title == "Pool Test Service"
    end

    test "pool tenants are isolated from each other" do
      ctx_a = TenantPool.checkout(:pool_a)
      ctx_b = TenantPool.checkout(:pool_b)

      Haul.Test.Factories.build_service(ctx_a.tenant, %{title: "Only In A"})

      # Query services in pool_b — should not see pool_a's service
      import Ash.Query, only: [filter: 2]

      {:ok, services} =
        Haul.Content.Service
        |> Ash.Query.for_read(:read)
        |> filter(title == "Only In A")
        |> Ash.read(tenant: ctx_b.tenant)

      assert services == []
    end
  end

  describe "groups/0" do
    test "returns the list of provisioned group names" do
      groups = TenantPool.groups()
      assert :pool_a in groups
      assert :pool_b in groups
      assert :pool_c in groups
      assert length(groups) == 3
    end
  end
end
