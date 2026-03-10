# T-031-01 Progress: compile-env-adapters

## Completed

- [x] Step 1: Added production adapter config to `config/prod.exs` (7 adapter selections)
- [x] Step 2: Removed adapter selections from `config/runtime.exs` (7 lines removed, API keys/secrets preserved)
- [x] Step 3: Converted all 7 modules to `Application.compile_env`:
  - [x] `lib/haul/ai.ex`
  - [x] `lib/haul/payments.ex`
  - [x] `lib/haul/billing.ex`
  - [x] `lib/haul/sms.ex`
  - [x] `lib/haul/places.ex`
  - [x] `lib/haul/domains.ex`
  - [x] `lib/haul/ai/chat.ex`
- [x] Step 4: Full test suite — 971 tests, 0 failures

## Deviations from Plan

None. Implementation was mechanical as expected.
