defmodule Haul.Admin.InitTaskTest do
  use ExUnit.Case, async: true

  alias Haul.Admin.InitTask

  describe "child_spec/1" do
    test "uses transient restart strategy" do
      spec = InitTask.child_spec([])
      assert spec.restart == :transient
      assert spec.id == InitTask
    end
  end

  describe "run/0" do
    test "completes without error" do
      # ensure_admin! is idempotent, safe to call again
      assert InitTask.run() in [:ok, :noop]
    end
  end
end
