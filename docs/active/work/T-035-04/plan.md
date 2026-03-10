# T-035-04 Plan: LiveView Event Helpers

## Step 1: Create LiveHelpers module

File: `test/support/live_helpers.ex`

Implement:
- `build_socket/1` — merge assigns into Socket struct with __changed__ and flash defaults
- `apply_event/4` — delegate to module.handle_event/3
- `apply_info/3` — delegate to module.handle_info/2
- `get_assign/2` — extract from {:noreply, socket} or {:reply, _, socket}

Verify: `mix compile` succeeds.

## Step 2: Create OnboardingLive unit tests

File: `test/haul_web/live/app/onboarding_live_unit_test.exs`

Tests:
- next: step 1→2, step 5→6, step 6 stays 6 (clamp)
- back: step 3→2, step 2→1, step 1 stays 1 (clamp)
- goto: valid step (3), boundary (1, 6), out of range (0, 7, 99), non-numeric edge
- validate_logo: returns socket unchanged

Verify: `mix test test/haul_web/live/app/onboarding_live_unit_test.exs` — all pass, each <10ms.

## Step 3: Create ChatLive unit tests

File: `test/haul_web/live/chat_live_unit_test.exs`

Tests for handle_event:
- update_input: sets :input assign
- update_input with no text key: returns socket unchanged
- toggle_profile: true→false, false→true
- go_live: sets finalized?, appends message to messages list
- go_live when already finalized: no-op
- send_message with empty text: no-op
- send_message when streaming?: no-op
- send_message when finalized?: no-op

Tests for handle_info:
- {:ai_chunk, text}: appends to last assistant message
- {:provisioning_complete, result}: sets provisioned_url, edit_mode?, provisioning? false
- {:provisioning_failed, _}: sets provisioning? false, appends error message
- {:DOWN, ref, ...} with matching task_ref + abnormal reason: clears streaming?
- {:DOWN, ref, ...} with matching extraction_ref: clears extraction_ref
- {:DOWN, ref, ...} with non-matching ref: no-op

Verify: `mix test test/haul_web/live/chat_live_unit_test.exs` — all pass, each <10ms.

## Step 4: Run stale tests to verify no regressions

`mix test --stale` — existing integration tests still pass.

## Step 5: Update test-architecture.md

Add "LiveView Event Helpers" section after existing Tier 1 documentation:
- Pattern description
- When to use / when not to use
- Example code

## Step 6: Run full suite + create review artifact

`mix test` — all tests pass. Write review.md.

## Testing Strategy

- New tests are Tier 1 (ExUnit.Case, async: true, no DB)
- Each test should be <10ms
- Existing integration tests stay — they cover rendering, routing, auth
- The unit tests add coverage for edge cases (boundary values, guard conditions) that integration tests don't cover well
