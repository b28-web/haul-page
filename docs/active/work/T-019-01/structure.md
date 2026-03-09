# T-019-01 Structure: Chat LiveView

## New Files

### `lib/haul/ai/chat.ex`
Chat conversation module. Public API + adapter pattern.

```
defmodule Haul.AI.Chat do
  @callback send_message(messages :: list(map()), system_prompt :: String.t()) ::
              {:ok, String.t()} | {:error, term()}
  @callback stream_message(messages :: list(map()), system_prompt :: String.t(), pid :: pid()) ::
              :ok | {:error, term()}

  def send_message(messages, system_prompt)  # delegates to adapter
  def stream_message(messages, system_prompt, pid)  # delegates to adapter
end
```

### `lib/haul/ai/chat/anthropic.ex`
Production adapter. Calls Anthropic Messages API via Req with SSE streaming.

```
defmodule Haul.AI.Chat.Anthropic do
  @behaviour Haul.AI.Chat

  def send_message(messages, system_prompt)  # non-streaming, for tests
  def stream_message(messages, system_prompt, pid)
    # POST to https://api.anthropic.com/v1/messages with stream: true
    # Parse SSE events, send {:ai_chunk, text} to pid
    # Send {:ai_done} on completion, {:ai_error, reason} on failure
end
```

### `lib/haul/ai/chat/sandbox.ex`
Test/dev adapter. Returns canned responses without API calls.

```
defmodule Haul.AI.Chat.Sandbox do
  @behaviour Haul.AI.Chat

  def set_response(response)  # per-process override
  def send_message(messages, system_prompt)  # returns fixture
  def stream_message(messages, system_prompt, pid)
    # Sends fixture in small chunks to simulate streaming
end
```

### `lib/haul_web/live/chat_live.ex`
Main chat LiveView. Public route at `/start`.

```
defmodule HaulWeb.ChatLive do
  use HaulWeb, :live_view

  @max_messages 50

  def mount/3
    # Load system prompt, init empty messages, generate session_id
  def render/1
    # Full-screen chat: header, scrollable messages, input bar
  def handle_event("send_message", ...)
    # Validate, rate limit, append user msg, spawn streaming task
  def handle_event("update_input", ...)
    # Update input field assign
  def handle_info({:ai_chunk, text}, ...)
    # Append text to current assistant message, push scroll event
  def handle_info({:ai_done}, ...)
    # Mark streaming complete
  def handle_info({:ai_error, reason}, ...)
    # Show error, mark streaming complete
  def handle_info({:DOWN, ref, :process, _pid, reason}, ...)
    # Handle task crash
end
```

### `assets/js/hooks/chat_scroll.js`
JS hook for auto-scrolling chat container.

```
export const ChatScroll = {
  mounted()   // push_event handler for "scroll_to_bottom"
  updated()   // auto-scroll if near bottom
}
```

### `test/haul/ai/chat_test.exs`
Unit tests for Chat module and Sandbox adapter.

### `test/haul_web/live/chat_live_test.exs`
LiveView tests for ChatLive — mount, send message, rate limiting, UI elements.

## Modified Files

### `lib/haul_web/router.ex`
Add `/start` route to `:tenant` live_session:
```
live_session :tenant, on_mount: [{HaulWeb.TenantHook, :resolve_tenant}] do
  live "/scan", ScanLive
  live "/book", BookingLive
  live "/pay/:job_id", PaymentLive
  live "/start", ChatLive          # NEW
end
```

### `assets/js/app.js`
Register ChatScroll hook:
```
import { ChatScroll } from "./hooks/chat_scroll"
hooks: {...colocatedHooks, StripePayment, AddressAutocomplete, ExternalRedirect, ChatScroll}
```

### `config/config.exs`
Add chat adapter config:
```
config :haul, :chat_adapter, Haul.AI.Chat.Sandbox
```

### `config/runtime.exs`
Switch to Anthropic adapter when API key present:
```
if anthropic_key = System.get_env("ANTHROPIC_API_KEY") do
  config :haul, :ai_adapter, Haul.AI.Baml
  config :haul, :chat_adapter, Haul.AI.Chat.Anthropic  # NEW
end
```

## Module Boundaries

```
HaulWeb.ChatLive
  ├── Haul.AI.Chat (behaviour + dispatch)
  │   ├── Haul.AI.Chat.Anthropic (prod — Req + SSE)
  │   └── Haul.AI.Chat.Sandbox (dev/test — fixtures)
  ├── Haul.AI.Prompt (load system prompt)
  └── Haul.RateLimiter (session rate limiting)

assets/js/hooks/chat_scroll.js → registered in app.js
```

## File Count
- **New:** 6 files (3 Elixir modules, 1 LiveView, 1 JS hook, 2 test files — but chat_test and chat_live_test count as 2)
- **Modified:** 4 files (router, app.js, config.exs, runtime.exs)
