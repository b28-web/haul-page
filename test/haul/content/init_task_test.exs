defmodule Haul.Content.InitTaskTest do
  use ExUnit.Case, async: true

  alias Haul.Content.InitTask
  alias Haul.Content.Loader

  describe "child_spec/1" do
    test "uses transient restart strategy" do
      spec = InitTask.child_spec([])
      assert spec.restart == :transient
      assert spec.id == InitTask
    end
  end

  describe "loaded state" do
    test "content is loaded after application startup" do
      # InitTask runs during app startup, so loaded?/0 should be true
      assert Loader.loaded?()
    end
  end
end
