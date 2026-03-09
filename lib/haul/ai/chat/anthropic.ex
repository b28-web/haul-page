defmodule Haul.AI.Chat.Anthropic do
  @moduledoc """
  Production chat adapter. Calls Anthropic Messages API via Req with SSE streaming.
  """

  @behaviour Haul.AI.Chat

  @api_url "https://api.anthropic.com/v1/messages"
  @model "claude-sonnet-4-20250514"
  @max_tokens 1024
  @api_version "2023-06-01"

  @impl true
  def send_message(messages, system_prompt) do
    body = build_body(messages, system_prompt, false)

    case Req.post(@api_url, json: body, headers: headers()) do
      {:ok, %{status: 200, body: %{"content" => [%{"text" => text} | _]}}} ->
        {:ok, text}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def stream_message(messages, system_prompt, pid) do
    body = build_body(messages, system_prompt, true)

    Task.start(fn ->
      try do
        stream_response(body, pid)
      rescue
        e -> send(pid, {:ai_error, Exception.message(e)})
      end
    end)

    :ok
  end

  defp stream_response(body, pid) do
    # Use a mutable agent for the SSE buffer since closures can't mutate
    {:ok, buf_agent} = Agent.start(fn -> "" end)

    into_fun = fn {:data, data}, acc ->
      old_buf = Agent.get(buf_agent, & &1)
      {new_buf, events} = parse_sse_data(old_buf <> data)
      Agent.update(buf_agent, fn _ -> new_buf end)

      for event <- events do
        case event do
          %{"type" => "content_block_delta", "delta" => %{"text" => text}} ->
            send(pid, {:ai_chunk, text})

          %{"type" => "message_stop"} ->
            send(pid, {:ai_done})

          %{"type" => "error", "error" => error} ->
            send(pid, {:ai_error, error})

          _ ->
            :ok
        end
      end

      {:cont, acc}
    end

    case Req.post(@api_url,
           json: body,
           headers: headers(),
           into: into_fun,
           receive_timeout: 60_000
         ) do
      {:ok, _resp} ->
        # Ensure done is sent if message_stop wasn't received
        remaining = Agent.get(buf_agent, & &1)
        Agent.stop(buf_agent)

        if remaining != "" do
          {_, events} = parse_sse_data(remaining <> "\n\n")

          for %{"type" => "content_block_delta", "delta" => %{"text" => text}} <- events do
            send(pid, {:ai_chunk, text})
          end
        end

        :ok

      {:error, reason} ->
        Agent.stop(buf_agent)
        send(pid, {:ai_error, reason})
        :ok
    end
  end

  defp build_body(messages, system_prompt, stream?) do
    api_messages =
      Enum.map(messages, fn msg ->
        %{"role" => to_string(msg.role), "content" => msg.content}
      end)

    body = %{
      "model" => @model,
      "max_tokens" => @max_tokens,
      "system" => system_prompt,
      "messages" => api_messages
    }

    if stream?, do: Map.put(body, "stream", true), else: body
  end

  defp headers do
    api_key = Application.get_env(:haul, :anthropic_api_key, System.get_env("ANTHROPIC_API_KEY"))

    [
      {"x-api-key", api_key},
      {"anthropic-version", @api_version},
      {"content-type", "application/json"}
    ]
  end

  @doc false
  def parse_sse_data(data) do
    # Split on double newlines (SSE event boundaries)
    parts = String.split(data, "\n\n")

    # Last part may be incomplete (no trailing \n\n)
    {complete, [remainder]} = Enum.split(parts, -1)

    events =
      complete
      |> Enum.reject(&(&1 == ""))
      |> Enum.flat_map(fn part ->
        part
        |> String.split("\n")
        |> Enum.find_value(fn
          "data: " <> json_str ->
            case Jason.decode(json_str) do
              {:ok, parsed} -> parsed
              _ -> nil
            end

          _ ->
            nil
        end)
        |> List.wrap()
      end)

    {remainder, events}
  end
end
