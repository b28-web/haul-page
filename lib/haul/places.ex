defmodule Haul.Places do
  @moduledoc """
  Places autocomplete behaviour. Dispatches to the adapter configured via
  `config :haul, :places_adapter`.

  Adapters:
  - `Haul.Places.Google` — production, calls Google Places (New) API
  - `Haul.Places.Sandbox` — dev/test, returns static suggestions
  """

  @callback autocomplete(input :: String.t()) :: {:ok, list(map())} | {:error, term()}

  @adapter Application.compile_env(:haul, :places_adapter, Haul.Places.Sandbox)

  @doc """
  Fetch autocomplete suggestions for the given input string.
  Delegates to the configured adapter.
  """
  def autocomplete(input) do
    @adapter.autocomplete(input)
  end
end
