defmodule HaulWeb.Helpers do
  @moduledoc false

  @doc """
  Access a field from a struct or map uniformly.
  """
  def get_field(%{__struct__: _} = struct, field), do: Map.get(struct, field)
  def get_field(map, field) when is_map(map), do: map[field]

  @doc """
  Convert an upload error atom to a human-readable string.
  """
  def friendly_upload_error(:too_large), do: "File is too large"
  def friendly_upload_error(:not_accepted), do: "File type not supported"
  def friendly_upload_error(:too_many_files), do: "Too many files"
  def friendly_upload_error(err), do: to_string(err)

  @doc """
  Collapse individual preferred_date_N params into a single preferred_dates list.
  """
  def merge_preferred_dates(params) do
    dates =
      ["preferred_date_1", "preferred_date_2", "preferred_date_3"]
      |> Enum.map(&Map.get(params, &1, ""))
      |> Enum.reject(&(&1 == "" || is_nil(&1)))

    params
    |> Map.put("preferred_dates", dates)
    |> Map.drop(["preferred_date_1", "preferred_date_2", "preferred_date_3"])
  end
end
