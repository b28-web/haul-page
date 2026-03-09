defmodule Haul.AI.Baml do
  @moduledoc """
  BAML AI adapter for production. Calls LLM via baml_elixir NIF.

  Requires `ANTHROPIC_API_KEY` env var to be set.
  BAML source files are read from the `baml/` directory at project root.
  """

  @behaviour Haul.AI

  @impl true
  def call_function(function_name, args) do
    client = %BamlElixir.Client{from: baml_source_path()}

    case BamlElixir.Client.call(client, function_name, args) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  defp baml_source_path do
    Application.get_env(:haul, :baml_source_path, "baml")
  end
end
