defmodule Haul.Places do
  @moduledoc """
  Places autocomplete behaviour. Dispatches to the adapter configured via
  `config :haul, :places_adapter`.

  Adapters:
  - `Haul.Places.Google` — production, calls Google Places (New) API
  - `Haul.Places.Sandbox` — dev/test, returns static suggestions
  """

  @callback autocomplete(input :: String.t()) :: {:ok, list(map())} | {:error, term()}

  @doc """
  Fetch autocomplete suggestions for the given input string.
  Delegates to the configured adapter.
  """
  def autocomplete(input) do
    adapter = Application.get_env(:haul, :places_adapter, Haul.Places.Sandbox)
    adapter.autocomplete(input)
  end
end
