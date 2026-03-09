# T-007-02 Progress: SMS Client

## Completed

- [x] Step 1: Created `Haul.SMS` behaviour module with `send_sms/3` callback and dispatch
- [x] Step 2: Created `Haul.SMS.Sandbox` adapter (logs + process message for test assertions)
- [x] Step 3: Created `Haul.SMS.Twilio` adapter (Req-based Twilio Messages API client)
- [x] Step 4: Added config entries in config.exs, test.exs, runtime.exs
- [x] Step 5: Wrote 4 tests — all passing
- [x] Step 6: Full test suite — 139 tests, 0 failures

## Deviations from Plan

None. Implementation followed the plan exactly.

## Files Created

- `lib/haul/sms.ex` — behaviour + public API
- `lib/haul/sms/sandbox.ex` — dev/test adapter
- `lib/haul/sms/twilio.ex` — production Twilio adapter
- `test/haul/sms_test.exs` — 4 tests

## Files Modified

- `config/config.exs` — added `:sms_adapter` default
- `config/test.exs` — added `:sms_adapter` for test env
- `config/runtime.exs` — added Twilio config in prod block
