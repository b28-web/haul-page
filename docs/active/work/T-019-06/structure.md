# T-019-06 Structure: Browser QA — Chat Onboarding

## Files

### Created
- `test/haul_web/live/chat_qa_test.exs` — End-to-end QA test module (~250 lines)

### Modified
- None. This ticket only adds tests.

### Deleted
- None.

## Module: `HaulWeb.ChatQATest`

```
defmodule HaulWeb.ChatQATest do
  use HaulWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Haul.AI.Chat.Sandbox, as: ChatSandbox

  setup:
    - clear_rate_limits()
    - ChatSandbox.clear_response()
    - ChatSandbox.clear_error()

  describe "chat UI layout":
    - header renders with title and manual signup link
    - welcome message shown when no messages
    - input field with placeholder and Send button
    - fallback link "Prefer a form?" below input
    - fallback link "or sign up manually" in header

  describe "full conversation flow":
    - multi-turn conversation builds profile progressively
    - user messages right-aligned, AI messages left-aligned
    - completeness indicator updates after extraction

  describe "streaming UX":
    - typing indicator appears during streaming (before content)
    - input disabled during streaming
    - input re-enabled after streaming completes

  describe "profile panel":
    - empty state before any messages
    - populated after extraction (business name, phone, email, etc.)
    - services list renders
    - differentiators list renders
    - progress bar reflects completeness
    - "Your profile is complete!" CTA when required fields present

  describe "mobile profile toggle":
    - toggle button appears when profile exists
    - toggle event shows/hides profile panel

  describe "provisioning flow":
    - "Build my site" button visible when profile complete
    - provisioning_complete shows site link
    - provisioning_failed shows error message

  describe "conversation persistence":
    - messages restored when same session_id reconnects

  describe "error recovery":
    - LLM not configured redirects to signup
    - first message error redirects to signup with flash
    - later message error shows flash, stays on page

  describe "rate limiting":
    - 50 message limit enforced with clear error message
end
```

## Dependencies

- `HaulWeb.ConnCase` — provides `conn`, `cleanup_tenants/0`, `clear_rate_limits/0`
- `Haul.AI.Chat.Sandbox` — deterministic AI responses
- `Haul.AI.Conversation` — Ash resource for persistence testing
- No new dependencies introduced

## Ordering

Single file creation. No ordering constraints.
