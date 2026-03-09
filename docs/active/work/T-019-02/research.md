# T-019-02 Research: Live Extraction

## Existing Infrastructure

### ChatLive (`lib/haul_web/live/chat_live.ex`, 262 lines)
- LiveView at `/start`, full-height flex layout with header/messages/input
- Socket assigns: `messages` (list of `%{id, role, content}`), `input`, `streaming?`, `message_count`, `session_id`, `system_prompt`, `task_ref`
- Async pattern: `Task.start` + `Process.monitor` for streaming, sends `{:ai_chunk, text}`, `{:ai_done}`, `{:ai_error, reason}` to LV pid
- `send_user_message/2` builds messages list, spawns stream task, adds placeholder assistant msg
- Rate limiting via `RateLimiter.check_rate/3` (50 msgs per session)

### Extractor (`lib/haul/ai/extractor.ex`, 72 lines)
- `extract_profile(transcript)` → `{:ok, OperatorProfile.t()}` | `{:error, term()}`
- Calls `Haul.AI.call_function("ExtractOperatorProfile", %{"transcript" => transcript})`
- Single retry on transient errors (timeout, rate limit, 429/500/502/503)
- `validate_completeness(profile)` → list of missing field atoms (checks business_name, phone, email, service_area, services)

### OperatorProfile (`lib/haul/ai/operator_profile.ex`, 92 lines)
- Struct: business_name, owner_name, phone, email, service_area, tagline, years_in_business, services (list), differentiators (list)
- Nested `ServiceOffering` struct: name, description, category (atom)
- `from_baml/1` parses string-keyed BAML output to typed struct

### ProfileMapper (`lib/haul/ai/profile_mapper.ex`)
- `missing_fields/1` → checks required fields [:business_name, :phone, :email]
- `to_site_config_attrs/1`, `to_service_attrs_list/1` — not needed for this ticket

### AI Adapter Pattern
- `Haul.AI` behaviour with `call_function/2` — dispatches to `Haul.AI.Sandbox` (dev/test) or `Haul.AI.Baml` (prod)
- `Haul.AI.Sandbox` uses process dictionary for overrides (process-scoped, works with `async: true`)
- `Haul.AI.Chat.Sandbox` uses ETS for overrides (cross-process, needed for streaming Tasks)

### Test Patterns
- ChatLive tests: `async: false`, `clear_rate_limits()` + `ChatSandbox.clear_response()` in setup
- Extractor tests: `async: true`, uses `Haul.AI.Sandbox.set_response/2` (process dict)
- LiveView tests: `Phoenix.LiveViewTest` with `live(conn, path)`, `form().render_submit()`, `Process.sleep` for async

## Key Constraints

1. **Extraction is synchronous** — `extract_profile/1` blocks while calling BAML API. Must run in separate Task to avoid blocking chat.
2. **Two concurrent async operations** — Chat streaming + extraction must coexist. Need separate task refs.
3. **Debounce requirement** — If user sends 3 messages rapidly, only extract on the last. Need timer-based debounce.
4. **Extraction errors must be silent** — No user-facing errors from extraction failures.
5. **Sandbox adapter uses process dictionary** — Tests spawning extraction in a Task won't see process-dict overrides. Need ETS-based approach or run extraction inline in tests.
6. **Profile fields: 7 trackable** — business_name, owner_name, phone, email, service_area, services, differentiators. Completeness = filled count / 7.

## Transcript Building
Messages are `%{role: :user | :assistant, content: string}`. Transcript for extraction:
```
user: Hello, I run a junk removal company
assistant: Great to meet you! What's your business name?
user: It's called QuickHaul
```

## UI Layout Considerations
- Current chat is full-height single-column
- Profile panel needs to sit alongside (desktop sidebar) or below (mobile card)
- Desktop: 2-column flex — chat left, profile right (fixed-width sidebar)
- Mobile: profile as collapsible card above input area, or bottom sheet
- Progress bar: simple div with width percentage
- Animations: Tailwind transition classes for opacity/color changes

## Completeness Tracking
Required fields per AC: business_name, phone, email, service_area, services, differentiators, + owner_name = 7 total
`validate_completeness/1` returns missing atoms. Completeness = 7 - length(missing).
"All required fields present" = business_name + phone + email present (per ProfileMapper.missing_fields).
