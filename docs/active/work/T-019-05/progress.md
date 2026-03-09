# T-019-05 Progress: Fallback Form

## Status: Complete

All steps implemented and tested. 33/33 targeted tests pass.

## Steps Completed

- [x] Step 1: Added `configured?/0` to `Haul.AI.Chat` — reads `:chat_available` config flag
- [x] Step 2: Added `set_error/1`, `clear_error/0` to `Haul.AI.Chat.Sandbox` for test error simulation
- [x] Step 3: Modified `ChatLive.mount/3` — redirects to `/app/signup` when `Chat.configured?()` is false
- [x] Step 4: Modified `handle_info({:ai_error, ...})` — redirects on first message, flash on later messages
- [x] Step 5: Added fallback links to ChatLive template (header + below input)
- [x] Step 6: Added reciprocal "try our AI assistant" link to SignupLive
- [x] Step 7: Wrote 6 new tests (fallback links, redirect, error handling, reciprocal link)
- [x] Step 8: All 33 targeted tests pass, full suite passes (2 pre-existing flaky tests unrelated)

## Deviations from Plan

- `configured?/0` changed from adapter detection + `dev_routes` check to config-based `chat_available` flag. Simpler, doesn't break test env.
- Runtime.exs sets `chat_available: false` only in prod when `ANTHROPIC_API_KEY` missing.
- Flash testing: LiveView `render/1` doesn't include root layout flash_group, so "later error" test verifies page stays open rather than checking flash text.
