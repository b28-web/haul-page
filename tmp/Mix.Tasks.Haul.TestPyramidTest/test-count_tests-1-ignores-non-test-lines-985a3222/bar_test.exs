defmodule FooTest do
  use ExUnit.Case, async: true

  # test "commented out" do
  describe "a group" do
    test "only this one" do
      assert true
    end
  end
end
