defmodule Haul.SMS.Twilio do
  @moduledoc """
  SMS adapter that sends messages via the Twilio Messages API.

  Requires config:

      config :haul, :twilio,
        account_sid: "ACxxxxx",
        auth_token: "xxxxxx",
        from_number: "+15551234567"
  """

  @behaviour Haul.SMS

  @impl true
  def send_sms(to, body, opts \\ []) do
    config = Application.get_env(:haul, :twilio, [])
    account_sid = Keyword.fetch!(config, :account_sid)
    auth_token = Keyword.fetch!(config, :auth_token)
    from_number = Keyword.get(opts, :from, Keyword.fetch!(config, :from_number))

    url = "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json"

    case Req.post(url,
           auth: {:basic, "#{account_sid}:#{auth_token}"},
           form: [{"To", to}, {"From", from_number}, {"Body", body}]
         ) do
      {:ok, %Req.Response{status: 201, body: resp_body}} ->
        {:ok, %{sid: resp_body["sid"], status: resp_body["status"]}}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        {:error,
         %{
           status: status,
           code: resp_body["code"],
           message: resp_body["message"]
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
