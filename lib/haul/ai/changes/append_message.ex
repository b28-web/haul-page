defmodule Haul.AI.Changes.AppendMessage do
  @moduledoc false
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument(changeset, :message) do
      nil ->
        Ash.Changeset.add_error(changeset, field: :message, message: "is required")

      message when is_map(message) ->
        current = Ash.Changeset.get_data(changeset, :messages) || []

        stamped =
          message
          |> Map.put_new("timestamp", DateTime.to_iso8601(DateTime.utc_now()))
          |> ensure_string_keys()

        Ash.Changeset.force_change_attribute(changeset, :messages, current ++ [stamped])
    end
  end

  defp ensure_string_keys(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
