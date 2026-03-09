# T-019-05 Structure: Fallback Form

## Files Modified

### 1. `lib/haul/ai/chat.ex`
- Add `configured?/0` public function
- Returns `true` if chat adapter is NOT Sandbox, or if dev_routes is enabled
- No new deps

### 2. `lib/haul/ai/chat/sandbox.ex`
- Add `set_error/1` — stores error in ETS (like `set_response/1`)
- Add `clear_error/0` — removes error from ETS
- Modify `stream_message/3` — check for error override, send `{:ai_error, error}` if set
- Add `get_error/0` private function

### 3. `lib/haul_web/live/chat_live.ex`

**mount/3:**
- After existing setup, check `Chat.configured?/0`
- If false: `{:ok, redirect(socket, to: ~p"/app/signup")}`
- Must return early before assigning other state (redirect in mount is special)

**render/1 template:**
- Header section (after subtitle): Add "Prefer a form?" link to `/app/signup`
- Below input form: Add "Or fill out a form instead" link to `/app/signup`

**handle_info({:ai_error, reason}, socket):**
- Check `socket.assigns.message_count == 1`
- If first message: redirect with flash "Chat is temporarily unavailable — use this form instead"
- If not first: existing behavior (flash error, stay on page)

### 4. `lib/haul_web/live/app/signup_live.ex`

**render/1 template:**
- Below "Already have an account? Sign in" link, add:
  "Want to try our AI assistant? Get started with chat" → link to `/start`

### 5. `test/haul_web/live/chat_live_test.exs`

New test blocks:
- `describe "fallback links"` — link renders in header and below input
- `describe "llm not configured"` — mount redirects to /app/signup
- `describe "first message error"` — redirects with flash
- `describe "later message error"` — stays on page with flash (existing behavior, but explicitly tested)

### 6. `test/haul_web/live/app/signup_live_test.exs`
- Add test: reciprocal chat link renders

## Files NOT Changed
- `lib/haul/onboarding.ex` — already shared pipeline, no changes needed
- `lib/haul_web/router.ex` — routes already exist
- `config/` — no config changes

## Module Boundaries
- `Chat.configured?/0` is the only new public API
- `ChatSandbox.set_error/1` and `clear_error/0` are test-only API additions
- All changes are in existing modules, no new files
