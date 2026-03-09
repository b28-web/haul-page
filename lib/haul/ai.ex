defmodule Haul.AI do
  @moduledoc """
  Behaviour and public API for structured LLM calls via BAML.

  Uses the adapter pattern — Sandbox for dev/test, Baml for prod.
  Configure via `config :haul, :ai_adapter, Haul.AI.Sandbox`.
  """

  @callback call_function(function_name :: String.t(), args :: map()) ::
              {:ok, map()} | {:error, any()}

  @doc """
  Call a BAML function by name with the given arguments.
  Delegates to the configured adapter.

  Options:
  - `:conversation_id` — UUID to link cost tracking to a conversation
  """
  def call_function(function_name, args \\ %{}, opts \\ []) do
    case adapter().call_function(function_name, args) do
      {:ok, result} = success ->
        Haul.AI.CostTracker.record_baml_call(function_name, args, result, opts)
        success

      error ->
        error
    end
  end

  defp adapter do
    Application.get_env(:haul, :ai_adapter, Haul.AI.Sandbox)
  end
end
