# T-007-02 Design: SMS Client

## Decision: Thin `req`-based Twilio wrapper with behaviour

### Option A: `ex_twilio` library
- **Pro:** Full Twilio API coverage, maintained by community
- **Con:** Heavy dependency for just sending SMS. Pulls in HTTPoison. We only need `Messages.create`.
- **Rejected:** Overkill. We need one API call.

### Option B: Thin `req`-based wrapper (chosen)
- **Pro:** No new deps (`req` already in mix.exs). Full control. Minimal code (~40 lines for Twilio adapter).
- **Pro:** Follows the project convention of minimal dependencies.
- **Con:** Must handle Twilio API errors ourselves.
- **Chosen:** Best fit for scope. Simple, testable, no new dependencies.

### Option C: GenServer-based SMS service
- **Pro:** Could queue messages, retry failures, rate limit.
- **Con:** Over-engineered for current needs. Can add later if needed.
- **Rejected:** YAGNI. Direct function calls are sufficient.

## Architecture

### Behaviour Module: `Haul.SMS`

Defines the callback and provides the public API that dispatches to the configured adapter:

```elixir
defmodule Haul.SMS do
  @callback send_sms(to :: String.t(), body :: String.t(), opts :: keyword()) ::
              {:ok, map()} | {:error, term()}

  def send_sms(to, body, opts \\ []) do
    adapter = Application.get_env(:haul, :sms_adapter, Haul.SMS.Sandbox)
    adapter.send_sms(to, body, opts)
  end
end
```

This mirrors how Swoosh dispatches to adapters via config, but since we're building our own behaviour (not using a library), the dispatch is explicit.

### Adapter: `Haul.SMS.Twilio`

Calls Twilio Messages API via `Req`:
- HTTP Basic auth with account_sid/auth_token from config
- POST form-encoded body
- Returns `{:ok, %{sid: ..., status: ...}}` or `{:error, reason}`
- Reads credentials from `Application.get_env(:haul, :twilio)`

### Adapter: `Haul.SMS.Sandbox`

For dev/test:
- Logs the message to Logger
- Stores messages in the process dictionary or an Agent for test assertions
- Returns `{:ok, %{sid: "sandbox-xxx", status: "sent"}}`

For testability, the Sandbox adapter will use `send(self(), {:sms_sent, message})` pattern so tests can assert on messages sent. This is simpler than an Agent and works with async tests.

### Config Pattern

```elixir
# config.exs (default for dev)
config :haul, :sms_adapter, Haul.SMS.Sandbox

# test.exs
config :haul, :sms_adapter, Haul.SMS.Sandbox

# runtime.exs (prod block)
config :haul, :sms_adapter, Haul.SMS.Twilio
config :haul, :twilio,
  account_sid: System.get_env("TWILIO_ACCOUNT_SID"),
  auth_token: System.get_env("TWILIO_AUTH_TOKEN"),
  from_number: System.get_env("TWILIO_FROM_NUMBER")
```

## Error Handling

The Twilio adapter returns:
- `{:ok, %{sid: string, status: string}}` on success (HTTP 201)
- `{:error, %{code: integer, message: string}}` on Twilio error
- `{:error, :request_failed}` on network/transport error

Callers (future tickets T-007-03, T-007-04) decide how to handle errors. The SMS module is a pure delivery client.

## Test Strategy

- Test the Sandbox adapter directly: call `send_sms/3`, assert on the process message
- Test the public `Haul.SMS.send_sms/3` dispatch (it uses Sandbox in test env)
- No Twilio API tests — that would require live credentials or a mock server
- The Twilio adapter's HTTP logic is simple enough to trust `req` + manual verification
