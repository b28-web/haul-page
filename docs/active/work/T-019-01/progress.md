# T-019-01 Progress: Chat LiveView

## Completed

### Step 1: Chat Adapter — Sandbox + Behaviour ✅
- Created `lib/haul/ai/chat.ex` — behaviour with `send_message/2` and `stream_message/3` callbacks
- Created `lib/haul/ai/chat/sandbox.ex` — ETS-based test adapter with global overrides
- Added `config :haul, :chat_adapter` to `config/config.exs`
- 6 tests passing in `test/haul/ai/chat_test.exs`

### Step 2: Chat Adapter — Anthropic (Production) ✅
- Created `lib/haul/ai/chat/anthropic.ex` — Req-based adapter with SSE streaming
- Updated `config/runtime.exs` to switch adapter when ANTHROPIC_API_KEY is set
- SSE parser handles `content_block_delta`, `message_stop`, and `error` events
- Uses Agent for mutable SSE buffer across streaming chunks

### Step 3: ChatScroll JS Hook ✅
- Created `assets/js/hooks/chat_scroll.js` — auto-scroll on new messages
- Registered in `assets/js/app.js`
- Handles `scroll_to_bottom` push_event and auto-scrolls on update if near bottom

### Step 4: ChatLive LiveView — Core ✅
- Created `lib/haul_web/live/chat_live.ex` — full chat UI
- Added `/start` route to public `:tenant` live_session in router
- Features: message bubbles, streaming, rate limiting, typing indicator, auto-scroll
- Mobile-responsive, dark theme, Enter-to-submit

### Step 5: Tests ✅
- 6 chat adapter tests (sandbox, dispatch)
- 9 LiveView tests (mount, send, rate limit, streaming, input management)
- All 15 tests passing

### Step 6: Full Suite Verification ✅
- 575 tests, 0 failures (1 excluded)
- No regressions from chat LiveView changes

## Deviations from Plan
- Sandbox uses ETS instead of process dictionary for cross-process test isolation
- Typing indicator shows only when streaming with empty assistant content (avoids flicker when first chunk arrives fast)
- Send button disabled when input is empty (UX improvement, not just during streaming)
