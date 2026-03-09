# T-007-02 Plan: SMS Client

## Step 1: Create behaviour module `Haul.SMS`

Create `lib/haul/sms.ex` with:
- `@callback send_sms/3` typespec
- Public `send_sms/3` function that dispatches to configured adapter
- Module doc explaining the adapter pattern

Verify: compiles without errors.

## Step 2: Create Sandbox adapter

Create `lib/haul/sms/sandbox.ex` with:
- `@behaviour Haul.SMS`
- `send_sms/3` that logs via Logger and sends `{:sms_sent, msg}` to caller
- Returns `{:ok, %{sid: "sandbox-<random>", status: "sent"}}`

Verify: compiles without errors.

## Step 3: Create Twilio adapter

Create `lib/haul/sms/twilio.ex` with:
- `@behaviour Haul.SMS`
- `send_sms/3` that calls Twilio Messages API via `Req.post`
- Reads credentials from `Application.get_env(:haul, :twilio)`
- Error handling for HTTP failures and Twilio error responses

Verify: compiles without errors.

## Step 4: Add config entries

- `config/config.exs`: add `config :haul, :sms_adapter, Haul.SMS.Sandbox`
- `config/test.exs`: add `config :haul, :sms_adapter, Haul.SMS.Sandbox`
- `config/runtime.exs`: add Twilio config in prod block (conditional on env vars)

Verify: `mix compile` succeeds.

## Step 5: Write tests

Create `test/haul/sms_test.exs`:
- Test `send_sms/3` delivers message struct via Sandbox
- Test message contains correct `to`, `body` fields
- Test `from` number comes from config (or opts override)
- Test return value shape

Verify: `mix test test/haul/sms_test.exs` passes.

## Step 6: Run full test suite

Verify: `mix test` — all existing tests still pass, new SMS tests pass.

## Commit Strategy

Single commit after all steps pass: "T-007-02: add SMS client with Twilio adapter and behaviour"
