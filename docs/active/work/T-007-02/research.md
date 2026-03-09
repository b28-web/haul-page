# T-007-02 Research: SMS Client

## Ticket Summary

Implement an SMS delivery system via Twilio with a behaviour-based adapter pattern, mirroring the Swoosh mailer pattern already in the codebase. Sandbox adapter for dev/test, Twilio adapter for prod.

## Existing Patterns

### Mailer (Swoosh) — the template to follow

The email system uses Swoosh's built-in adapter pattern:
- `lib/haul/mailer.ex` — `use Swoosh.Mailer, otp_app: :haul` + helper functions
- `config/config.exs` — `adapter: Swoosh.Adapters.Local` (dev default)
- `config/test.exs` — `adapter: Swoosh.Adapters.Test`
- `config/runtime.exs` — Postmark or Resend adapter selected via env vars in prod
- `test/haul/mailer_test.exs` — uses `Swoosh.TestAssertions` for send verification

Key pattern: adapter selection via config, not dependency injection. The adapter module is stored in application config and used at runtime.

### Dependencies

- `{:req, "~> 0.5"}` is already in mix.exs — can use for HTTP calls to Twilio API
- `{:jason, "~> 1.2"}` is already in mix.exs — JSON encoding/decoding
- No `ex_twilio` dependency exists. Ticket says to consider thin `req`-based wrapper.

### Runtime Config Pattern

`config/runtime.exs` reads env vars and conditionally configures adapters. The mailer section uses a `cond` block to pick Postmark vs Resend based on which env var is set. SMS config should follow same pattern.

### Operator Config

`config :haul, :operator` stores business identity including phone number. The SMS "from" number is separate (Twilio number) but operator phone could be relevant for display purposes.

### Test Environment

- `config/test.exs` sets `Swoosh.Adapters.Test` and `config :swoosh, :api_client, false`
- Tests use `ExUnit.Case, async: true` where possible
- No database needed for SMS tests (pure function testing)

## Twilio Messages API

The Twilio REST API for sending SMS:
- Endpoint: `https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Messages.json`
- Auth: HTTP Basic (account_sid:auth_token)
- Method: POST
- Body: form-encoded (`To`, `From`, `Body`)
- Response: JSON with `sid`, `status`, `error_code`, etc.

This is simple enough for a thin `req` wrapper — no need for the full `ex_twilio` library.

## File Locations

New files needed:
- `lib/haul/sms.ex` — behaviour definition
- `lib/haul/sms/twilio.ex` — Twilio adapter
- `lib/haul/sms/sandbox.ex` — dev/test adapter (logs to console)
- `test/haul/sms_test.exs` — tests using sandbox adapter

Config changes:
- `config/config.exs` — default SMS adapter (Sandbox)
- `config/test.exs` — SMS adapter set to Sandbox
- `config/runtime.exs` — Twilio adapter + env vars in prod block

## Constraints

- No Twilio calls in test or dev — enforced by adapter config
- Env vars: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`
- The behaviour must be swappable — downstream tickets (T-007-03 booking-confirmation, T-007-04 job-notifications) will call `Haul.SMS.send_sms/3`
- No new dependencies needed — `req` handles HTTP, `jason` handles JSON
