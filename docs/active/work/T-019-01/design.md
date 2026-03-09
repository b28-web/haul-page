# T-019-01 Design: Chat LiveView

## Decision 1: Chat API Backend — Direct Anthropic API via Req

**Options:**
1. **BAML `call_function`** — Reuse existing adapter. But BAML is for structured extraction, not free-form chat. No streaming. Would need new BAML function returning raw string.
2. **Direct Anthropic Messages API via Req** — Call `https://api.anthropic.com/v1/messages` with streaming. Full control over conversation history, system prompt, streaming.
3. **Add `chat/2` to BAML adapter** — Extend the behaviour with a chat callback. More abstraction than needed.

**Decision: Option 2 — Direct Anthropic API via Req.**
- Chat is fundamentally different from structured extraction. Different API shape (messages array vs single input).
- Req already available. Supports streaming via `:into` option.
- Keeps BAML for what it's good at (typed extraction in T-019-02).
- New module `Haul.AI.Chat` handles conversation calls with adapter pattern for test sandboxing.

## Decision 2: Streaming Architecture

**Options:**
1. **Task.async + send** — Spawn task, stream chunks via `send/2`, handle in `handle_info`.
2. **LiveView async_result** — Use Phoenix 1.1 `assign_async`. But designed for one-shot loads, not streaming.
3. **GenServer intermediary** — Overkill for per-session state.

**Decision: Option 1 — Task.async + send.**
- Spawn a Task that calls Anthropic API with streaming enabled.
- Req streams SSE chunks. Task parses `data:` lines and sends `{:ai_chunk, text}` to LiveView pid.
- LiveView `handle_info` appends chunks to current assistant message and pushes scroll event.
- On completion, Task sends `{:ai_done}`. LiveView sets `streaming? = false`.
- On error, Task sends `{:ai_error, reason}`. LiveView shows error flash.

## Decision 3: Conversation State Model

**State in socket assigns:**
```
messages: [%{id: uuid, role: :user | :assistant, content: string}]
input: ""
streaming?: false
message_count: 0
session_id: uuid (for rate limiting key)
system_prompt: string (loaded once in mount)
task_ref: reference | nil (for monitoring streaming task)
```

No database persistence — that's T-019-03. State lives and dies with the LiveView process.

## Decision 4: Message Format for API

Anthropic Messages API expects:
```json
{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}
```

Map directly from socket assigns. System prompt goes in the `system` parameter.

## Decision 5: Sandbox/Test Strategy

**Chat adapter pattern:**
- `Haul.AI.Chat` module with `send_message(messages, system_prompt)` function
- Config-driven adapter: `config :haul, :chat_adapter, Haul.AI.Chat.Sandbox`
- Sandbox returns canned responses without API calls
- Sandbox supports per-process overrides like `Haul.AI.Sandbox`

## Decision 6: UI Layout

**Mobile-first, single column:**
- Full-height viewport (`h-dvh`) with flex column
- Header bar: app name/logo, minimal
- Message area: scrollable, flex-grow
- Input area: fixed bottom, text input + send button
- No sidebar (profile sidebar is T-019-02)

**Message bubbles:**
- User: right-aligned, accent background (slightly lighter gray)
- AI: left-aligned, card background
- Rounded corners, padding, max-width ~85%
- Typing indicator: three pulsing dots during streaming

**Dark theme:** Uses existing CSS variables (`--background`, `--card`, `--foreground`, `--border`).

## Decision 7: Rate Limiting

- Use existing `Haul.RateLimiter.check_rate/3`
- Key: `{:chat, session_id}` where session_id is generated in mount
- Limit: 50 messages per session (window: 86400 seconds — effectively per-session since LiveView dies)
- Also track `message_count` in assigns as primary check (faster than ETS lookup)

## Decision 8: Route Placement

`/start` in the public `:tenant` live_session alongside `/scan`, `/book`, `/pay/:job_id`.
- Gets tenant resolution via TenantHook
- No auth required
- Uses root layout (no admin sidebar)

## Decision 9: JS Hook — ChatScroll

Minimal JS hook for auto-scroll behavior:
- `mounted()` — observe container for new children (MutationObserver or event-based)
- `handleEvent("scroll_to_bottom")` — smooth scroll to bottom
- Called after each message append and each streaming chunk

## Rejected Approaches

- **Phoenix Streams** for messages — overkill for a bounded list (max ~100 messages per session). Simple list assign with `Enum.reverse` for display is cleaner.
- **Channel-based chat** — LiveView already has bidirectional communication. Extra channel adds complexity without benefit.
- **WebSocket to Anthropic** — Anthropic API uses HTTP SSE, not WebSocket. Req handles this fine.
- **Database-backed messages** — explicitly deferred to T-019-03. Process state is sufficient.
