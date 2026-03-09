# T-019-01 Plan: Chat LiveView

## Step 1: Chat Adapter — Sandbox + Behaviour

Create `lib/haul/ai/chat.ex` with behaviour and adapter dispatch.
Create `lib/haul/ai/chat/sandbox.ex` with fixture responses.
Add `config :haul, :chat_adapter` to `config/config.exs`.

**Test:** `test/haul/ai/chat_test.exs`
- Sandbox returns default response
- `set_response/1` overrides per-process
- `stream_message/3` sends chunks + done to caller pid

**Verify:** `mix test test/haul/ai/chat_test.exs`

## Step 2: Chat Adapter — Anthropic (Production)

Create `lib/haul/ai/chat/anthropic.ex`.
- `send_message/2` — POST to Anthropic Messages API, non-streaming
- `stream_message/3` — POST with `stream: true`, parse SSE, send chunks to pid
- Parse `content_block_delta` events for text tokens
- Handle `message_stop` event
- Error handling for API failures, timeouts

Update `config/runtime.exs` to set `:chat_adapter` when API key present.

**Test:** Manual only (requires API key). Sandbox tests cover the interface.

## Step 3: ChatScroll JS Hook

Create `assets/js/hooks/chat_scroll.js`.
Register in `assets/js/app.js`.

**Behaviour:**
- `mounted()` — listen for `scroll_to_bottom` push_event, scroll container
- `updated()` — auto-scroll if user is near bottom (within 100px)
- Smooth scrolling for UX

**Verify:** Visual in browser.

## Step 4: ChatLive LiveView — Core

Create `lib/haul_web/live/chat_live.ex`.
Add `/start` route to router.

**Mount:**
- Load system prompt via `Haul.AI.Prompt.load("onboarding_agent")`
- Initialize assigns: messages=[], input="", streaming?=false, message_count=0, session_id

**Events:**
- `send_message` — validate non-empty, check rate limit, append user message, spawn streaming task
- `update_input` — update input assign (for controlled input)

**Handle_info:**
- `{:ai_chunk, text}` — append to last assistant message content
- `{:ai_done}` — set streaming?=false, demonitor task
- `{:ai_error, reason}` — flash error, set streaming?=false
- `{:DOWN, ...}` — handle task crash

**Render:**
- Full-screen flex layout with header, scrollable message area, input bar
- Message bubbles: user (right, lighter bg), assistant (left, card bg)
- Typing indicator (3 pulsing dots) when streaming
- Disabled input + send button when streaming
- Mobile-responsive (works at 375px)

**Verify:** `mix test test/haul_web/live/chat_live_test.exs`

## Step 5: Tests

`test/haul_web/live/chat_live_test.exs`:
- Mounts at `/start` with empty chat
- Shows page title
- Sends message and receives AI response
- Rate limiting after 50 messages
- Empty message rejected
- Typing indicator shown during streaming
- Input disabled during streaming
- Auto-scroll event pushed

## Step 6: Polish & Verify

- Run full test suite: `mix test`
- Check mobile layout visually
- Verify dark theme consistency
- Ensure Enter-to-submit works
- Check rate limiting behavior

## Commit Strategy

1. Commit after Step 1+2: "T-019-01: add AI chat adapter with sandbox and Anthropic backends"
2. Commit after Steps 3+4+5: "T-019-01: chat LiveView at /start with streaming AI responses"
3. Final commit after Step 6: "T-019-01: polish chat UI and finalize tests"
