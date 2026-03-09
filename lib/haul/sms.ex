defmodule Haul.SMS do
  @moduledoc """
  SMS delivery behaviour. Dispatches to the adapter configured via
  `config :haul, :sms_adapter`.

  Adapters:
  - `Haul.SMS.Twilio` — production, calls Twilio Messages API
  - `Haul.SMS.Sandbox` — dev/test, logs messages and notifies the calling process
  """

  @callback send_sms(to :: String.t(), body :: String.t(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}

  @doc """
  Send an SMS message. Delegates to the configured adapter.

  Options are adapter-specific. The Twilio adapter accepts:
  - `:from` — override the default "from" number
  """
  def send_sms(to, body, opts \\ []) do
    adapter = Application.get_env(:haul, :sms_adapter, Haul.SMS.Sandbox)
    adapter.send_sms(to, body, opts)
  end
end
