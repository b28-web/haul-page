defmodule Haul.Sortable do
  @moduledoc false

  @doc """
  Find the indices for a swap operation.
  Returns `{:ok, current_idx, swap_idx}` or `:error` if the move is invalid.
  """
  def find_swap_index(items, id, direction) do
    idx = Enum.find_index(items, &(&1.id == id))

    swap_idx =
      case direction do
        :up -> idx && idx - 1
        :down -> idx && idx + 1
      end

    if idx && swap_idx && swap_idx >= 0 && swap_idx < length(items) do
      {:ok, idx, swap_idx}
    else
      :error
    end
  end

  @doc """
  Compute the next sort_order value for a list of items.
  Each item must have a `sort_order` field.
  """
  def next_sort_order([]), do: 0
  def next_sort_order(items), do: (items |> Enum.map(& &1.sort_order) |> Enum.max()) + 1
end
