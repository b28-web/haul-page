defmodule Haul.AI.Chat.Sandbox do
  @moduledoc """
  Sandbox chat adapter for dev/test. Returns fixture responses without calling any LLM.

  Supports per-process overrides via ETS keyed by caller PID. Cross-process lookups
  (e.g., LiveView calling stream_message) walk the `$callers` ancestry chain to find
  overrides registered by the test process. Safe for async: true.
  """

  @behaviour Haul.AI.Chat

  @table __MODULE__
  @default_response "Thanks for sharing! I'm your onboarding assistant. Could you tell me about your business? What's the name of your company?"

  @doc """
  Override the chat response for the calling process.
  Cross-process callers (LiveView, Tasks) find this override via
  the `$callers` ancestry chain.
  """
  def set_response(response) when is_binary(response) do
    ensure_table()
    :ets.insert(@table, {{self(), :response}, response})
    :ok
  end

  @doc """
  Override the chat adapter to return an error instead of a response.
  Scoped to the calling process (and its descendants via `$callers`).
  """
  def set_error(error) do
    ensure_table()
    :ets.insert(@table, {{self(), :error}, error})
    :ok
  end

  @doc """
  Clear the error override for the calling process.
  """
  def clear_error do
    if :ets.whereis(@table) != :undefined do
      :ets.delete(@table, {self(), :error})
    end

    :ok
  end

  @doc """
  Clear the response override for the calling process.
  """
  def clear_response do
    if :ets.whereis(@table) != :undefined do
      :ets.delete(@table, {self(), :response})
    end

    :ok
  end

  @impl true
  def send_message(_messages, _system_prompt) do
    {:ok, lookup(:response, @default_response)}
  end

  @impl true
  def stream_message(_messages, _system_prompt, pid) do
    case lookup(:error, nil) do
      nil ->
        response = lookup(:response, @default_response)

        # Simulate streaming by sending the response in small chunks
        Task.start(fn ->
          response
          |> String.graphemes()
          |> Enum.chunk_every(3)
          |> Enum.each(fn chars ->
            send(pid, {:ai_chunk, Enum.join(chars)})
            Process.sleep(5)
          end)

          send(pid, {:ai_done})
        end)

        :ok

      error ->
        Task.start(fn ->
          send(pid, {:ai_error, error})
        end)

        :ok
    end
  end

  # Look up a key for the current process, then walk $callers ancestry chain.
  # This mirrors how Ecto.Adapters.SQL.Sandbox resolves ownership —
  # LiveView and Task processes inherit their test process's overrides.
  defp lookup(key, default) do
    pids = [self() | Process.get(:"$callers", [])]
    lookup_chain(pids, key, default)
  end

  defp lookup_chain([], _key, default), do: default

  defp lookup_chain([pid | rest], key, default) do
    if :ets.whereis(@table) != :undefined do
      case :ets.lookup(@table, {pid, key}) do
        [{{^pid, ^key}, value}] -> value
        [] -> lookup_chain(rest, key, default)
      end
    else
      default
    end
  end

  defp ensure_table do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :set, :public])
    end
  end
end
