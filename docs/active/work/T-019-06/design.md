# T-019-06 Design: Browser QA — Chat Onboarding

## Decision: Test Approach

### Option A: Phoenix LiveViewTest (chosen)
All prior browser QA tickets use `Phoenix.LiveViewTest`. This provides deterministic, fast tests with full DOM assertion capabilities. Consistent with project conventions.

### Option B: Playwright MCP browser automation
Would enable real viewport testing, CSS verification, and screenshot comparison. However: no prior QA ticket uses this pattern, it adds external dependencies to CI, and the chat's async streaming is harder to synchronize in a real browser. The ticket title says "browser-qa" but the established pattern is LiveViewTest.

### Option C: Mix of both
Hybrid approach — LiveViewTest for logic, Playwright for visual spot-checks. Over-engineered for the value delivered.

**Decision: Option A.** Follow the established project pattern. LiveViewTest covers all acceptance criteria except actual CSS rendering (which is a design review concern, not a QA automation concern).

## Test File

`test/haul_web/live/chat_qa_test.exs` — new file, separate from the existing unit-level `chat_live_test.exs`. QA tests exercise end-to-end flows (multi-turn conversations, provisioning lifecycle, session resumption) rather than isolated behaviors.

## Test Structure

### 1. Full Conversation Flow (multi-turn)
Send 3+ messages simulating a real onboarding conversation. Verify:
- User messages appear in order
- AI responses appear after each
- Profile panel progressively fills
- Completeness indicator advances from 0/7 → 7/7

### 2. Chat UI Layout Verification
- Header: title "Get Started", subtitle with manual signup link
- Welcome message when no messages yet
- Message bubbles: user right-aligned (class `justify-end`), AI left-aligned (`justify-start`)
- Input: text field + Send button, placeholder "Type a message..."
- "Prefer a form?" link below input with href `/app/signup`

### 3. Streaming UX
- Input disabled during streaming (`disabled` attribute present)
- Typing indicator: bouncing dots div present while streaming and before content arrives
- After streaming completes: input re-enabled, typing indicator gone

### 4. Profile Panel
- Desktop: visible in sidebar (`.md:block.w-80`)
- Empty state: "Start chatting to build your profile..."
- After extraction: fields populated, progress bar width > 0%
- Services list with service names
- Differentiators list
- Complete state: "Your profile is complete!" + "Build my site" button

### 5. Mobile Profile Toggle
- Toggle button only appears when profile exists
- `toggle_profile` event shows/hides profile panel
- Panel visibility controlled by `show_profile?` assign

### 6. Provisioning Flow
- "Build my site" button visible when profile complete
- Click triggers provisioning state (button shows "Building your site...")
- Simulate `provisioning_complete` → "Your site is live!" + "View your site" link
- Simulate `provisioning_failed` → error message, can retry

### 7. Conversation Persistence
- Send messages, note session_id
- Create new conn with same session_id in session
- Mount at `/start` → previous messages restored

### 8. Error Handling (end-to-end)
- LLM not configured → redirect to `/app/signup`
- First message error → redirect with flash
- Later message error → stay on page with flash

### 9. Fallback Access
- "or sign up manually" link in header → `/app/signup`
- "Fill out a form instead" link below input → `/app/signup`

## Test Helpers

Reuse existing patterns:
- `ChatSandbox.set_response/1` and `ChatSandbox.set_error/1` for deterministic AI responses
- `clear_rate_limits/0` in setup
- `Process.sleep/1` for async operations (500ms for streaming, 1500ms for extraction)

## Risks

- **Timing sensitivity**: Extraction debounce (800ms) + task execution needs generous sleeps. Prior tests use 1500ms successfully.
- **Sandbox adapter determinism**: Tests rely on Sandbox returning a known profile. If Sandbox internals change, tests break — acceptable since Sandbox is test infrastructure.
- **No real viewport testing**: Mobile toggle test exercises the event handler, not actual viewport behavior. Acceptable given project pattern.
