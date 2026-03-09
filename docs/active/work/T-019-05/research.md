# T-019-05 Research: Fallback Form

## Ticket Summary

Provide graceful fallback from AI chat onboarding (`/start`) to manual signup form (`/signup`) when the LLM is unavailable or operator prefers a traditional form.

## Relevant Files

### Primary — Will Be Modified

1. **`lib/haul_web/live/chat_live.ex`** (567 lines)
   - LiveView at `/start` for conversational onboarding
   - Mounts with system_prompt, messages, streaming state, profile extraction
   - Streams LLM responses via `Chat.stream_message/3` in spawned Task
   - Handles `{:ai_error, reason}` at line 345 — shows flash, resets streaming state
   - Template has header (line 55-69), messages area (79-125), input form (127-165), profile sidebar (168-171)
   - No fallback links or LLM-unavailable detection currently

2. **`lib/haul/ai/chat/sandbox.ex`** (75 lines)
   - Test/dev adapter. Returns fixture responses
   - `set_response/1` allows overriding response globally via ETS
   - No way to simulate errors currently — needs `set_error/1` for testing

3. **`test/haul_web/live/chat_live_test.exs`** (266 lines)
   - Tests mount, send_message, rate limiting, streaming, extraction
   - Uses `ChatSandbox.set_response/1` for fixtures
   - No tests for error handling, fallback links, or redirect behavior

### Secondary — Read Only

4. **`lib/haul_web/live/app/signup_live.ex`** (230 lines)
   - LiveView at `/app/signup` for manual form-based signup
   - Fields: name, email, phone, area, password, password_confirmation
   - Calls `Onboarding.signup/1` — same provisioning pipeline as chat path
   - Has honeypot, rate limiting, slug availability check
   - No "prefer chat?" link back to `/start`

5. **`lib/haul/onboarding.ex`** (284 lines)
   - `signup/1` — web form path (accepts password)
   - `run/1` — chat path (no password, creates passwordless owner)
   - Both call same provisioning steps: find_or_create_company → seed_content → update_site_config → create owner
   - Already shared pipeline — AC requirement satisfied by existing design

6. **`lib/haul/ai/chat.ex`** (38 lines)
   - Behavior module with adapter pattern
   - `adapter/0` reads `:chat_adapter` from config, defaults to Sandbox
   - No function to check if LLM is configured/available

7. **`config/runtime.exs`** (lines 86-94)
   - Sets `:chat_adapter` to `Haul.AI.Chat.Anthropic` only if `ANTHROPIC_API_KEY` env var is set
   - Otherwise defaults to `Haul.AI.Chat.Sandbox` from config.exs
   - Detection: `Application.get_env(:haul, :chat_adapter) == Haul.AI.Chat.Sandbox` could indicate no real LLM

8. **`lib/haul_web/router.ex`** (101 lines)
   - `/start` → ChatLive (in `:tenant` live_session with TenantHook)
   - `/app/signup` → App.SignupLive (in public `/app` scope, no live_session)
   - Different live_sessions = can't `push_navigate` between them; must use `redirect`

## Key Observations

### LLM Availability Detection

The ticket says "If LLM API key is not configured: `/start` redirects to `/signup` silently." Detection approach:

- **Option A:** Check `Application.get_env(:haul, :chat_adapter)` — if it's Sandbox, no real LLM is configured. Simple but Sandbox is also used in dev intentionally.
- **Option B:** Check `Application.get_env(:haul, :anthropic_api_key)` — if nil, no API key. More direct.
- **Option C:** Add a `configured?/0` function to the Chat module. Clean interface.

Option B is most direct. In prod, if ANTHROPIC_API_KEY is not set, the chat adapter stays as Sandbox. But we don't want to redirect in dev/test. So we should check: `config_env() == :prod and no API key` OR check the adapter specifically.

Actually, the cleanest approach: check if the chat adapter is the Anthropic adapter in prod. In dev/test, Sandbox is expected and we don't redirect. But the ticket says "if not configured" — this means prod without API key. A simple `Haul.AI.Chat.configured?/0` that checks for the API key is cleanest.

### Error on First Message → Auto-redirect

"If LLM API returns error on first message: auto-redirect to `/signup`" — need to track whether this is the first message. `message_count == 1` at the point of error means it was the first. Redirect with flash.

### Cross-LiveSession Navigation

`/start` is in live_session `:tenant`, `/app/signup` is NOT in a live_session (just a scope). They can't share a live_session, so navigation must use `redirect/2` (full page redirect), not `push_navigate`.

### Flash Across Redirect

`Phoenix.LiveView.redirect/2` preserves flash messages set via `put_flash/3` — they travel through the session and display on the next page load.

### Signup Form Already Has Flash Group

`SignupLive` renders `<HaulWeb.Layouts.flash_group flash={@flash} />` at line 40, so flashes from redirect will display correctly.

## Constraints

- Both paths (`/start` and `/app/signup`) already feed into the same `Onboarding` module — no integration work needed
- `/start` and `/app/signup` are in different live_sessions — must use `redirect/2`
- Sandbox adapter is used in dev/test intentionally — "not configured" should only trigger redirect in production OR when explicitly set
- The chat page template needs two links: one at the top ("Prefer a form?") and one persistently visible during conversation ("Fill out a form instead")
- Error detection on first message requires knowing message_count at error time

## Open Questions

- Should the "not configured" redirect also apply when using Sandbox in dev? Probably not — devs want to test the chat flow with Sandbox. Only redirect when adapter is Sandbox AND env is prod (meaning API key wasn't set).
- Should we add a config flag `:chat_enabled` for operators who prefer form-only? Could be future work — not in AC.
