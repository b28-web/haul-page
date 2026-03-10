defmodule Haul.AI.Message do
  @moduledoc false

  @doc """
  Build a plaintext transcript from a list of messages.
  """
  def build_transcript(messages) do
    messages
    |> Enum.reject(&(&1.content == ""))
    |> Enum.map(fn msg -> "#{msg.role}: #{msg.content}" end)
    |> Enum.join("\n")
  end

  @doc """
  Append text to the last assistant message in the list.
  Returns the list unchanged if the last message is not an assistant message.
  """
  def append_to_last_assistant(messages, text) do
    case List.last(messages) do
      %{role: :assistant} = msg ->
        updated = %{msg | content: msg.content <> text}
        List.replace_at(messages, -1, updated)

      _ ->
        messages
    end
  end

  @doc """
  Check if the last message is a non-empty assistant message.
  """
  def has_assistant_content?(messages) do
    case List.last(messages) do
      %{role: :assistant, content: content} when content != "" -> true
      _ -> false
    end
  end

  @doc """
  Recursively convert structs to plain maps.
  """
  def deep_to_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Map.new(fn {k, v} -> {k, deep_to_map(v)} end)
  end

  def deep_to_map(list) when is_list(list), do: Enum.map(list, &deep_to_map/1)
  def deep_to_map(value), do: value

  @doc """
  Convert stored DB messages (string-keyed maps) to runtime message maps with atom keys.
  """
  def restore_messages(db_messages) when is_list(db_messages) do
    Enum.map(db_messages, fn msg ->
      %{
        id: Ecto.UUID.generate(),
        role: String.to_existing_atom(msg["role"]),
        content: msg["content"] || ""
      }
    end)
  end

  def restore_messages(_), do: []
end
