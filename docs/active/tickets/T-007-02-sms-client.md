---
id: T-007-02
story: S-007
title: sms-client
type: task
status: open
priority: high
phase: ready
depends_on: [T-001-06]
---

## Context

Set up SMS delivery via Twilio using `ex_twilio` (or a thin `req`-based wrapper if `ex_twilio` proves too heavy). Define a behaviour so the SMS backend is swappable in tests.

## Acceptance Criteria

- `Haul.SMS` behaviour module with `send_sms(to, body, opts)` callback
- `Haul.SMS.Twilio` adapter implementing the behaviour, calling Twilio Messages API
- `Haul.SMS.Sandbox` adapter for dev/test that logs messages instead of sending
- Adapter selection via `config :haul, :sms_adapter` in runtime config
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER` read from env
- Unit test using Sandbox adapter verifies message struct is correct
- No Twilio calls in test or dev environments
