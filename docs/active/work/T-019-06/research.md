# T-019-06 Research: Browser QA — Chat Onboarding

## Scope

End-to-end browser verification of the conversational onboarding chat at `/start`. This is the signature UX — chat-driven business profile collection with live extraction, streaming responses, and fallback paths.

## Key Files

### Chat LiveView
- `lib/haul_web/live/chat_live.ex` — Main LiveView (710 lines). Dual-panel layout: chat messages left, profile sidebar right (desktop) / toggleable card (mobile). Session-based via `chat_session_id` cookie. Streams AI responses, debounced profile extraction (800ms), provisioning via Oban worker.

### Chat Backend
- `lib/haul/ai/chat.ex` — Adapter pattern: `configured?/0`, `stream_message/3`. Config-driven adapter selection.
- `lib/haul/ai/chat/sandbox.ex` — Dev/test adapter. ETS-backed response overrides (`set_response/1`, `set_error/1`). Simulates streaming via 3-char chunks with 5ms delays. Default response includes full profile data.
- `lib/haul/ai/chat/anthropic.ex` — Production adapter. Claude Sonnet, SSE streaming.

### Extraction Pipeline
- `lib/haul/ai/extractor.ex` — `extract_profile/1` calls BAML function, returns `OperatorProfile`. `validate_completeness/1` returns missing field atoms. Required: business_name, phone, email, service_area, services.
- `lib/haul/ai/operator_profile.ex` — Struct with 9 fields (7 tracked in UI). Nested `ServiceOffering` struct with category enum.
- `lib/haul/ai/profile_mapper.ex` — Maps profile to company/site_config/services attrs.

### Conversation Persistence
- `lib/haul/ai/conversation.ex` — Ash resource. `session_id` (unique), `messages` (array of maps), `extracted_profile` (map), `status` (active/completed/abandoned/provisioning/failed). Actions: `:start`, `:by_session_id`, `:add_message`, `:save_profile`, `:link_to_company`.

### Supporting Infrastructure
- `lib/haul_web/plugs/ensure_chat_session.ex` — Generates UUID session cookie if missing.
- `lib/haul_web/router.ex` — `/start` maps to `ChatLive` in tenant live_session. `/app/signup` is the fallback form.
- `assets/js/hooks/chat_scroll.js` — Auto-scroll with 100px threshold. `scroll_to_bottom` event handler.
- `priv/prompts/onboarding_agent.md` — System prompt loaded at mount.

### Existing Tests
- `test/haul_web/live/chat_live_test.exs` — 335 lines, 16 tests covering mount, send_message, rate limiting, streaming, live extraction, profile complete CTA, fallback links, LLM-not-configured redirect, first/later message errors. Uses `ChatSandbox` for deterministic responses.

## Patterns from Prior QA Tickets

All browser QA tickets (T-012-05, T-013-06, T-014-03, T-015-04, T-016-04, T-017-03) use `Phoenix.LiveViewTest` — NOT actual Playwright browser automation. Pattern:
- `use HaulWeb.ConnCase, async: false`
- `import Phoenix.LiveViewTest`
- Setup creates test context (tenant, user, etc.), teardown calls `cleanup_tenants()`
- Tests exercise full user flows via `live/2`, `render_submit/3`, `render_click/3`
- Test file named `*_qa_test.exs`

## What Existing Tests Cover vs What QA Must Verify

### Already covered (chat_live_test.exs):
- Mount renders page with title, welcome text, placeholder
- Profile sidebar empty state ("0 of 7 fields collected")
- Send message → receive AI response
- Empty/whitespace rejection
- Input clearing after send
- Rate limiting (50 messages)
- Input disabled during streaming, re-enabled after
- Profile panel updates (business name, phone, email, completeness %, services, differentiators)
- Profile complete CTA ("Build my site")
- Extraction error/crash resilience
- Fallback links (header + below input)
- LLM-not-configured redirect
- First message error redirect vs later message flash

### QA must additionally verify:
1. **Full conversation flow** — multi-turn conversation with realistic messages, verifying profile builds progressively
2. **Dark theme elements** — message bubble styling (user=zinc-700, AI=card+border)
3. **Typing indicator** — bouncing dots appear during streaming before content arrives
4. **Progress bar** — visual completeness indicator updates
5. **Mobile profile toggle** — "View Profile" / "Hide Profile" button appears on mobile (conceptual — LiveViewTest can't test viewport, but can verify toggle event)
6. **Provisioning flow** — "Build my site" → provisioning state → success/failure
7. **Conversation persistence** — same session_id resumes previous conversation
8. **"Prefer a form?" link** — exact text and href verification
9. **Message bubble layout** — user messages right-aligned, AI left-aligned
10. **System prompt loading** — fallback prompt used when file missing

## Constraints

- Sandbox adapter returns deterministic profile data. Default: "Junk & Handy", Mike Johnson, (555) 123-4567, mike@junkandhandy.com, Portland metro area, 3 services, 2 differentiators.
- Extraction debounce is 800ms + task execution. Tests need ~1500ms sleep for extraction results.
- Streaming simulation uses 5ms delays per 3-char chunk. Short responses complete in <100ms.
- Rate limiter uses ETS — `clear_rate_limits()` in setup.
- Conversation resource needs domain/Ash setup. ConnCase handles tenant creation.
