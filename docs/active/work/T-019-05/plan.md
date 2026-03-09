# T-019-05 Plan: Fallback Form

## Step 1: Add `configured?/0` to Chat module

**File:** `lib/haul/ai/chat.ex`

Add public function:
```elixir
def configured? do
  adapter() != Haul.AI.Chat.Sandbox or
    Application.get_env(:haul, :dev_routes, false)
end
```

**Verify:** `mix compile --no-deps-check`

## Step 2: Add error simulation to Sandbox

**File:** `lib/haul/ai/chat/sandbox.ex`

- Add `set_error/1` — stores `{:error, value}` in ETS
- Add `clear_error/0` — deletes error key from ETS
- Modify `stream_message/3` — check `get_error()` first; if set, send `{:ai_error, error}` to pid and return
- Add private `get_error/0` — reads from ETS, returns nil if not set

**Verify:** `mix compile --no-deps-check`

## Step 3: Modify ChatLive mount for redirect

**File:** `lib/haul_web/live/chat_live.ex`

In `mount/3`, after the existing socket setup, add:
```elixir
if not Chat.configured?() do
  {:ok, redirect(socket, to: ~p"/app/signup")}
else
  {:ok, socket |> assign(...)}
end
```

**Verify:** `mix test test/haul_web/live/chat_live_test.exs` (existing tests still pass — Sandbox is "configured" in test because dev_routes may be set; we'll handle this in tests)

## Step 4: Add first-message error redirect

**File:** `lib/haul_web/live/chat_live.ex`

Modify `handle_info({:ai_error, reason}, socket)`:
```elixir
def handle_info({:ai_error, reason}, socket) do
  if socket.assigns.message_count == 1 do
    {:noreply,
     socket
     |> put_flash(:error, "Chat is temporarily unavailable — use this form instead")
     |> redirect(to: ~p"/app/signup")}
  else
    # existing error handling
  end
end
```

**Verify:** `mix compile --no-deps-check`

## Step 5: Add fallback links to ChatLive template

**File:** `lib/haul_web/live/chat_live.ex`

- After subtitle in header: `<a href="/app/signup">Prefer a form? Sign up manually</a>`
- Below input form (after message limit warning): `<a href="/app/signup">Or fill out a form instead</a>`

**Verify:** `mix test test/haul_web/live/chat_live_test.exs`

## Step 6: Add reciprocal link to SignupLive

**File:** `lib/haul_web/live/app/signup_live.ex`

After "Already have an account? Sign in" paragraph, add:
```heex
<p class="text-center text-sm text-muted-foreground">
  Or <.link navigate={~p"/start"} class="text-foreground underline">try our AI assistant</.link>
</p>
```

**Verify:** Visual check or test

## Step 7: Write tests

**File:** `test/haul_web/live/chat_live_test.exs`

New describe blocks:
- "fallback links" — assert links render in HTML
- "llm not configured" — temporarily override configured? or use Sandbox error
- "first message error" — use `ChatSandbox.set_error/1`, send message, assert redirect

**File:** `test/haul_web/live/app/signup_live_test.exs`
- Assert "/start" link renders

**Verify:** `mix test test/haul_web/live/chat_live_test.exs test/haul_web/live/app/signup_live_test.exs`

## Step 8: Full test suite

**Verify:** `mix test`
