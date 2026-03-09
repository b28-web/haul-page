# T-007-02 Structure: SMS Client

## New Files

### `lib/haul/sms.ex`
- Defines `@callback send_sms(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}`
- Public function `send_sms/3` that reads `:sms_adapter` from config and delegates
- ~20 lines

### `lib/haul/sms/twilio.ex`
- `@behaviour Haul.SMS`
- Implements `send_sms/3` using `Req.post!/2` to Twilio Messages API
- Reads `:twilio` config for credentials
- Handles HTTP response codes (201 = success, others = error)
- ~45 lines

### `lib/haul/sms/sandbox.ex`
- `@behaviour Haul.SMS`
- Implements `send_sms/3` by logging and sending `{:sms_sent, msg}` to calling process
- Returns `{:ok, %{sid: "sandbox-...", status: "sent"}}`
- ~20 lines

### `test/haul/sms_test.exs`
- Tests `Haul.SMS.send_sms/3` via Sandbox adapter (configured in test env)
- Asserts message struct contains correct `to`, `body`, `from` fields
- Tests error cases (empty to, empty body)
- ~50 lines

## Modified Files

### `config/config.exs`
- Add: `config :haul, :sms_adapter, Haul.SMS.Sandbox`
- After the mailer config line

### `config/test.exs`
- Add: `config :haul, :sms_adapter, Haul.SMS.Sandbox`

### `config/runtime.exs`
- In the `if config_env() == :prod` block, add Twilio config section
- Reads `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`
- Sets `:sms_adapter` to `Haul.SMS.Twilio` and `:twilio` credentials
- Only configures if env vars are present (SMS is optional — not all operators need it)

## Module Boundaries

- `Haul.SMS` is the public API. All callers use `Haul.SMS.send_sms/3`.
- `Haul.SMS.Twilio` and `Haul.SMS.Sandbox` are internal adapters, not called directly.
- No coupling to Ash domain resources — this is a pure service client.
- Future tickets will call `Haul.SMS.send_sms/3` from notification workflows.

## No Changes To

- `mix.exs` — no new dependencies needed
- Database/migrations — SMS is stateless
- Router — no new routes
- LiveView/controllers — downstream tickets handle that
