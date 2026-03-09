# T-019-01 Review: Chat LiveView

## Summary

Built a conversational chat LiveView at `/start` for operator onboarding. The operator types naturally, an AI agent responds with follow-up questions, and responses stream in token-by-token. The interface is mobile-first (375px), dark-themed, and rate-limited to 50 messages per session.

## Files Created (7)

| File | Purpose |
|------|---------|
| `lib/haul/ai/chat.ex` | Chat behaviour + adapter dispatch (send_message, stream_message) |
| `lib/haul/ai/chat/sandbox.ex` | Dev/test adapter — ETS-based fixture responses with streaming simulation |
| `lib/haul/ai/chat/anthropic.ex` | Production adapter — Anthropic Messages API via Req with SSE streaming |
| `lib/haul_web/live/chat_live.ex` | Main chat LiveView — full UI with streaming, rate limiting, auto-scroll |
| `assets/js/hooks/chat_scroll.js` | JS hook for auto-scrolling chat container on new messages |
| `test/haul/ai/chat_test.exs` | 6 tests for chat adapter (sandbox, dispatch) |
| `test/haul_web/live/chat_live_test.exs` | 9 tests for ChatLive (mount, send, rate limit, streaming) |

## Files Modified (4)

| File | Change |
|------|--------|
| `lib/haul_web/router.ex` | Added `live "/start", ChatLive` to public `:tenant` live_session |
| `assets/js/app.js` | Imported and registered ChatScroll hook |
| `config/config.exs` | Added `config :haul, :chat_adapter, Haul.AI.Chat.Sandbox` |
| `config/runtime.exs` | Switch to `Haul.AI.Chat.Anthropic` when ANTHROPIC_API_KEY present |

## Test Coverage

**15 new tests, all passing. 575 total tests, 0 failures.**

| Area | Tests | What's covered |
|------|-------|----------------|
| Chat Sandbox | 4 | Default response, override, streaming chunks, done signal |
| Chat Dispatch | 2 | Module delegates to configured adapter |
| ChatLive Mount | 2 | Page renders, empty state with welcome text |
| ChatLive Send | 4 | Send + receive response, empty rejected, whitespace rejected, input clears |
| ChatLive Rate Limit | 1 | 50-message limit enforced |
| ChatLive Streaming | 2 | Input disabled during streaming, re-enabled after |

## Acceptance Criteria Coverage

| Criterion | Status | Notes |
|-----------|--------|-------|
| `/start` LiveView page (public, no auth) | ✅ | In `:tenant` live_session, no auth required |
| Message bubbles (user right, AI left) | ✅ | Distinct styling with rounded corners, max-width 85% |
| Text input with send button and Enter-to-submit | ✅ | Form with phx-submit, button disabled when empty |
| Streaming AI responses | ✅ | Task + send pattern, chunks appended to last assistant message |
| Auto-scroll to latest message | ✅ | ChatScroll JS hook with push_event |
| Typing indicator while AI responding | ✅ | 3 pulsing dots, shown before first chunk arrives |
| Mobile-responsive (375px) | ✅ | Full-height flex layout, no overflow issues |
| Dark theme consistent | ✅ | Uses existing CSS variables (--background, --card, etc.) |
| Conversation state in LiveView process | ✅ | No DB persistence, process memory only |
| System prompt from config | ✅ | Loaded via `Haul.AI.Prompt.load("onboarding_agent")` |
| Rate limiting (50 messages/session) | ✅ | Both in-assign count and ETS-backed RateLimiter |

## Architecture Decisions

1. **Direct Anthropic API for chat, not BAML** — BAML is for structured extraction (typed outputs). Chat needs free-form text responses. Separate adapter pattern keeps concerns clean.

2. **ETS-based sandbox overrides** — Process dictionary doesn't work across LiveView test boundaries. ETS table with global overrides ensures test setup is visible to LiveView and its spawned tasks.

3. **Task.start + Process.monitor for streaming** — Spawns an unlinked task for API calls. LiveView monitors it for crash detection. Messages flow via send/handle_info.

4. **Agent for SSE buffer in Anthropic adapter** — Req streaming closures can't mutate local variables. Agent holds the partial-line buffer between SSE chunks.

## Open Concerns

1. **Anthropic adapter untested in CI** — Requires real API key. Only sandbox adapter is tested automatically. Manual verification needed before prod deploy.

2. **SSE parsing edge cases** — The `parse_sse_data/1` function handles standard cases but hasn't been tested against malformed SSE streams or connection drops mid-event.

3. **No conversation persistence** — By design (deferred to T-019-03). Page refresh loses all messages.

4. **Rate limit reset** — Session-scoped rate limit resets on page reload. Determined operators could bypass by refreshing. IP-based limiting could be added later if needed.

5. **No error recovery during streaming** — If the API call fails mid-stream, the partial response stays visible. Could be improved with rollback logic.

## Dependencies Satisfied

- **T-019-04** (onboarding agent prompt) — System prompt loaded via `Haul.AI.Prompt.load("onboarding_agent")`
- **T-018-03** (extraction function) — Not used directly by T-019-01, but the chat adapter pattern mirrors and complements the extraction adapter

## Downstream Impact

- **T-019-02** (live extraction) — Will integrate with ChatLive to extract profile from conversation transcript
- **T-019-03** (persistence) — Will add database backing to the in-memory conversation state
- **T-019-05** (fallback form) — Alternative input method, same route/LiveView
