defmodule Haul.Test.TenantPoolGroupTest do
  @moduledoc """
  Integration test verifying that concurrency group opt-in works end-to-end.
  Uses `async: true, group: :pool_a` to get automatic tenant context injection.
  Requires async: true — the group: tag only works with async mode.
  Skipped until T-035-02 (process-local test state) makes async safe suite-wide.
  """
  use HaulWeb.ConnCase, async: true, group: :pool_a

  @moduletag :pool_infra

  test "receives pool tenant context from setup", %{
    tenant: tenant,
    company: company,
    user: user,
    token: token,
    conn: conn
  } do
    assert is_binary(tenant)
    assert String.contains?(tenant, "pool_a")
    assert company.slug == "__pool_a__"
    assert to_string(user.email) == "admin@example.com"
    assert is_binary(token)
    assert conn
  end

  test "can use pool tenant for resource operations", %{tenant: tenant} do
    service = Haul.Test.Factories.build_service(tenant, %{title: "Group Test"})
    assert service.title == "Group Test"
  end
end
