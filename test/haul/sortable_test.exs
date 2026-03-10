defmodule Haul.SortableTest do
  use ExUnit.Case, async: true

  alias Haul.Sortable

  describe "find_swap_index/3" do
    test "move up returns correct indices" do
      items = [%{id: "a"}, %{id: "b"}, %{id: "c"}]
      assert Sortable.find_swap_index(items, "b", :up) == {:ok, 1, 0}
    end

    test "move down returns correct indices" do
      items = [%{id: "a"}, %{id: "b"}, %{id: "c"}]
      assert Sortable.find_swap_index(items, "b", :down) == {:ok, 1, 2}
    end

    test "move up first item returns error" do
      items = [%{id: "a"}, %{id: "b"}]
      assert Sortable.find_swap_index(items, "a", :up) == :error
    end

    test "move down last item returns error" do
      items = [%{id: "a"}, %{id: "b"}]
      assert Sortable.find_swap_index(items, "b", :down) == :error
    end

    test "unknown id returns error" do
      items = [%{id: "a"}]
      assert Sortable.find_swap_index(items, "z", :up) == :error
    end

    test "empty list returns error" do
      assert Sortable.find_swap_index([], "a", :up) == :error
    end
  end

  describe "next_sort_order/1" do
    test "empty list returns 0" do
      assert Sortable.next_sort_order([]) == 0
    end

    test "returns max + 1" do
      items = [%{sort_order: 0}, %{sort_order: 2}, %{sort_order: 1}]
      assert Sortable.next_sort_order(items) == 3
    end

    test "single item" do
      assert Sortable.next_sort_order([%{sort_order: 5}]) == 6
    end
  end
end
