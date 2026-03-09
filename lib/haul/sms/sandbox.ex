defmodule Haul.SMS.Sandbox do
  @moduledoc """
  SMS adapter for dev/test. Logs messages and notifies the calling process
  so tests can assert on sent messages.
  """

  @behaviour Haul.SMS

  require Logger

  @impl true
  def send_sms(to, body, opts \\ []) do
    message = %{
      to: to,
      body: body,
      from: Keyword.get(opts, :from, "sandbox"),
      sid: "sandbox-#{System.unique_integer([:positive])}",
      status: "sent"
    }

    Logger.info("[SMS Sandbox] To: #{to} — #{body}")
    send(self(), {:sms_sent, message})

    {:ok, message}
  end
end
