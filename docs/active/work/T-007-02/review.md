# T-007-02 Review: SMS Client

## Summary

Implemented an SMS delivery system with a behaviour-based adapter pattern. Three modules: `Haul.SMS` (behaviour + dispatch), `Haul.SMS.Twilio` (production adapter), and `Haul.SMS.Sandbox` (dev/test adapter). No new dependencies added — uses existing `req` for HTTP.

## Changes

### New Files
| File | Purpose | Lines |
|------|---------|-------|
| `lib/haul/sms.ex` | Behaviour definition + public `send_sms/3` API | 23 |
| `lib/haul/sms/sandbox.ex` | Dev/test adapter — logs + process message | 22 |
| `lib/haul/sms/twilio.ex` | Production adapter — Twilio Messages API via Req | 38 |
| `test/haul/sms_test.exs` | 4 tests via Sandbox adapter | 33 |

### Modified Files
| File | Change |
|------|--------|
| `config/config.exs` | Added `config :haul, :sms_adapter, Haul.SMS.Sandbox` |
| `config/test.exs` | Added `config :haul, :sms_adapter, Haul.SMS.Sandbox` |
| `config/runtime.exs` | Added Twilio config block in prod (conditional on env vars) |

## Test Coverage

- **4 new tests**, all passing
- Tests cover: message delivery, process notification, from-number override, default from value
- **Full suite: 139 tests, 0 failures**
- No Twilio API integration tests (by design — would require live credentials)

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| `Haul.SMS` behaviour with `send_sms(to, body, opts)` callback | ✅ |
| `Haul.SMS.Twilio` adapter calling Twilio Messages API | ✅ |
| `Haul.SMS.Sandbox` adapter for dev/test that logs | ✅ |
| Adapter selection via `config :haul, :sms_adapter` | ✅ |
| `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER` from env | ✅ |
| Unit test using Sandbox verifies message struct | ✅ |
| No Twilio calls in test or dev | ✅ |

## Design Decisions

1. **No new dependencies** — `req` (already in mix.exs) handles Twilio HTTP calls. No `ex_twilio`.
2. **Twilio config is optional in prod** — SMS not required for all operators. The runtime.exs block only activates if `TWILIO_ACCOUNT_SID` is set. If not set, the Sandbox adapter remains active (which just logs).
3. **Process message pattern for testing** — `send(self(), {:sms_sent, msg})` allows tests to use `assert_received` without shared state or Agents.

## Open Concerns

- **No integration test for Twilio adapter** — The `Req.post` call path is untested against a real API. Manual verification needed before first prod deploy with Twilio enabled.
- **No retry logic** — If Twilio is down, `send_sms` fails immediately. Acceptable for now; downstream tickets (T-007-03, T-007-04) can add retry/queue logic if needed.
- **Rate limiting** — Twilio has rate limits. Not handled. Unlikely to be an issue at current scale.

## Downstream Impact

- `Haul.SMS.send_sms/3` is the public API for T-007-03 (booking-confirmation) and T-007-04 (job-notifications)
- The behaviour is stable — adding new adapters only requires implementing the callback
