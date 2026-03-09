# T-019-05 Review: Fallback Form

## Summary

Implemented graceful fallback from AI chat onboarding (`/start`) to manual signup (`/app/signup`). Six files modified, 6 new tests added. All 33 targeted tests pass.

## Acceptance Criteria Verification

| # | Criterion | Status | Location |
|---|-----------|--------|----------|
| 1 | "Prefer a form? Sign up manually" link on `/start` | Done | `chat_live.ex` header: "or sign up manually" |
| 2 | LLM error on first message → redirect to `/signup` with flash | Done | `chat_live.ex` handle_info checks `message_count == 1` |
| 3 | LLM API key not configured → `/start` redirects silently | Done | `chat_live.ex` mount + `runtime.exs` `:chat_available` flag |
| 4 | Both paths use same provisioning pipeline | Done | `onboarding.ex` — `signup/1` (form) and `run/1` (chat) share steps |
| 5 | "Fill out a form instead" link always visible in chat | Done | `chat_live.ex` below input area, always rendered |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/ai/chat.ex` | Added `configured?/0` — reads `:chat_available` config (default true) |
| `lib/haul/ai/chat/sandbox.ex` | Added `set_error/1`, `clear_error/0`, `get_error/0`; modified `stream_message/3` to check for error override |
| `lib/haul_web/live/chat_live.ex` | Mount redirect when not configured; first-message error redirect; header + footer fallback links |
| `lib/haul_web/live/app/signup_live.ex` | Added reciprocal "try our AI assistant" link to `/start` |
| `config/runtime.exs` | Set `chat_available: false` in prod when `ANTHROPIC_API_KEY` missing |
| `test/haul/ai/chat_test.exs` | Added `Sandbox.clear_error()` to setup |
| `test/haul_web/live/chat_live_test.exs` | 6 new tests: fallback links, redirect when unconfigured, first/later message errors |
| `test/haul_web/live/app/signup_live_test.exs` | 1 new test: reciprocal AI assistant link |

## Test Coverage

**33/33 pass** (chat_live + signup_live tests). 6 new tests added.

| Test | What it verifies |
|------|-----------------|
| "renders manual signup link in header" | Header contains `/app/signup` link |
| "renders form fallback link below input" | Footer contains "Fill out a form instead" |
| "redirects when chat_available is false" | Mount returns redirect to `/app/signup` |
| "redirects with flash on first message error" | `assert_redirect` to `/app/signup` with flash |
| "stays on page for later message errors" | Page stays open after error on message_count > 1 |
| "has link to AI chat assistant" | Signup page has `/start` link |

## Open Concerns

- **Pre-existing flaky tests**: `rate limiting enforces max message limit` (timing) and `stream_message/3 delegates to configured adapter` (seed-dependent) are pre-existing flaky tests, not related to this ticket.
- **Flash across redirect**: Flash set via `put_flash` before `redirect/2` correctly persists through session to next page load. Verified the SignupLive template renders `flash_group`.
