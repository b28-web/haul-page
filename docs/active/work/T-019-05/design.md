# T-019-05 Design: Fallback Form

## Requirements Recap

1. "Prefer a form? Sign up manually" link on `/start`
2. LLM error on first message → auto-redirect to `/signup` with flash
3. LLM API key not configured → `/start` redirects to `/signup` silently
4. Both paths use same provisioning pipeline (already true)
5. "Fill out a form instead" link always visible in chat

## Design Decisions

### 1. LLM Availability Check

**Chosen: `Haul.AI.Chat.configured?/0`**

Add a function to the Chat module:
```elixir
def configured? do
  adapter() != Haul.AI.Chat.Sandbox or
    Application.get_env(:haul, :dev_routes, false)
end
```

Logic: If the adapter is Sandbox AND we're NOT in dev mode, the LLM is "not configured." In dev, Sandbox is intentional (dev_routes is true). In test, we control this per-test.

**Rejected alternatives:**
- Checking `Application.get_env(:haul, :anthropic_api_key)` directly — leaks adapter knowledge into the LiveView
- Checking `Mix.env()` — not available at runtime in releases

### 2. Silent Redirect When Not Configured

In `ChatLive.mount/3`, after setup, check `Chat.configured?/0`. If false, return `{:ok, socket |> redirect(to: ~p"/app/signup")}`.

Phoenix LiveView handles redirect in mount — the client will navigate before rendering.

### 3. First-Message Error → Redirect

In the existing `handle_info({:ai_error, reason}, socket)` handler:
- If `socket.assigns.message_count == 1` (only the user's first message was sent), redirect to `/signup` with flash
- If `message_count > 1`, show error flash as currently (user has invested in the conversation)

This is simple and uses existing state.

### 4. UI Links

**Header link:** Below the subtitle "Tell us about your business", add:
```
Prefer a form? <a href="/app/signup">Sign up manually</a>
```

**Persistent link during conversation:** Below the input form area, add:
```
Or <a href="/app/signup">fill out a form instead</a>
```

Always visible, not conditional. Light styling (text-muted-foreground, underline).

### 5. Sandbox Error Simulation

Add `set_error/1` to `Haul.AI.Chat.Sandbox`:
```elixir
def set_error(error) do
  ensure_table()
  :ets.insert(@table, {:error, error})
end
```

In `stream_message/3`, check for error override before streaming:
```elixir
case get_error() do
  nil -> # normal streaming
  error -> send(pid, {:ai_error, error})
end
```

### 6. Signup Form — Reciprocal Link

Add "Prefer to chat? Get started with AI" link on signup form pointing to `/start`. Keeps the two paths discoverable from each other.

## Architecture

```
/start (ChatLive)
  mount → Chat.configured?() == false → redirect to /app/signup
  mount → Chat.configured?() == true → render chat
  send_message → ai_error + message_count == 1 → redirect to /app/signup with flash
  send_message → ai_error + message_count > 1 → flash error (existing behavior)
  UI: "Prefer a form?" link in header, "fill out a form" link below input

/app/signup (SignupLive)
  UI: "Prefer to chat? Try our AI assistant" link
  Everything else unchanged
```

## Test Strategy

1. Mount with `configured?` returning false → redirects to `/signup`
2. First message error → redirects with flash
3. Later message error → shows flash, stays on page
4. Fallback links render in chat page
5. Reciprocal link renders in signup page
