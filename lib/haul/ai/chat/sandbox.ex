defmodule Haul.AI.Chat.Sandbox do
  @moduledoc """
  Sandbox chat adapter for dev/test. Returns fixture responses without calling any LLM.

  Supports global overrides via ETS for cross-process test isolation.
  """

  @behaviour Haul.AI.Chat

  @table __MODULE__
  @default_response "Thanks for sharing! I'm your onboarding assistant. Could you tell me about your business? What's the name of your company?"

  @doc """
  Override the chat response globally (visible across all processes).
  Call this from your test setup.
  """
  def set_response(response) when is_binary(response) do
    ensure_table()
    :ets.insert(@table, {:response, response})
    :ok
  end

  @doc """
  Override the chat adapter to return an error instead of a response.
  Call this from your test setup to simulate LLM failures.
  """
  def set_error(error) do
    ensure_table()
    :ets.insert(@table, {:error, error})
    :ok
  end

  @doc """
  Clear the error override.
  """
  def clear_error do
    if :ets.whereis(@table) != :undefined do
      :ets.delete(@table, :error)
    end

    :ok
  end

  @doc """
  Clear the response override.
  """
  def clear_response do
    if :ets.whereis(@table) != :undefined do
      :ets.delete(@table, :response)
    end

    :ok
  end

  @impl true
  def send_message(_messages, _system_prompt) do
    {:ok, get_response()}
  end

  @impl true
  def stream_message(_messages, _system_prompt, pid) do
    case get_error() do
      nil ->
        response = get_response()

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

  defp get_error do
    if :ets.whereis(@table) != :undefined do
      case :ets.lookup(@table, :error) do
        [{:error, value}] -> value
        [] -> nil
      end
    else
      nil
    end
  end

  defp get_response do
    if :ets.whereis(@table) != :undefined do
      case :ets.lookup(@table, :response) do
        [{:response, value}] -> value
        [] -> @default_response
      end
    else
      @default_response
    end
  end

  defp ensure_table do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :set, :public])
    end
  end
end
