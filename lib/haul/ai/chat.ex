defmodule Haul.AI.Chat do
  @moduledoc """
  Conversational chat with an LLM. Adapter pattern — Sandbox for dev/test, Anthropic for prod.

  Configure via `config :haul, :chat_adapter, Haul.AI.Chat.Sandbox`.
  """

  @type message :: %{role: :user | :assistant, content: String.t()}

  @callback send_message(messages :: [message()], system_prompt :: String.t()) ::
              {:ok, String.t()} | {:error, term()}

  @callback stream_message(messages :: [message()], system_prompt :: String.t(), pid :: pid()) ::
              :ok | {:error, term()}

  @adapter Application.compile_env(:haul, :chat_adapter, Haul.AI.Chat.Sandbox)

  @doc """
  Returns true if chat is available. Checks the `:chat_available` config flag,
  which defaults to true. Set to false in production when ANTHROPIC_API_KEY is missing.
  """
  def configured? do
    Application.get_env(:haul, :chat_available, true)
  end

  @doc """
  Send a message and get a complete response (non-streaming).
  """
  def send_message(messages, system_prompt) do
    @adapter.send_message(messages, system_prompt)
  end

  @doc """
  Send a message and stream the response as chunks to the given pid.

  The pid will receive:
  - `{:ai_chunk, text}` — a text token
  - `{:ai_done}` — streaming complete
  - `{:ai_error, reason}` — an error occurred
  """
  def stream_message(messages, system_prompt, pid) do
    @adapter.stream_message(messages, system_prompt, pid)
  end
end
