# T-019-06 Plan: Browser QA — Chat Onboarding

## Step 1: Create test file with setup

Create `test/haul_web/live/chat_qa_test.exs` with module definition, imports, and setup block. Follow the established QA test pattern from billing_qa_test.exs and domain_qa_test.exs.

Verify: File compiles with `mix compile --warnings-as-errors`.

## Step 2: Chat UI layout tests

Add describe block for initial page state:
- Header title "Get Started"
- Welcome text "help set up your business page"
- Input placeholder "Type a message..."
- Send button
- Fallback links: "or sign up manually" (href /app/signup), "Fill out a form instead" (href /app/signup), "Prefer a form?"

Verify: `mix test test/haul_web/live/chat_qa_test.exs` passes.

## Step 3: Full conversation flow test

Multi-turn conversation:
1. Send "I run a junk removal business called Joe's Hauling in Portland"
2. Wait for streaming + extraction
3. Verify user message appears, AI response appears
4. Verify profile panel shows extracted data
5. Verify completeness indicator shows 7/7 (sandbox default fills all)

Verify: Test passes with 1500ms sleep for extraction.

## Step 4: Streaming UX tests

- Submit message, immediately check: input has `disabled` attribute
- After streaming completes (500ms): input no longer disabled
- Typing indicator: submit message, render immediately — check for bounce animation divs

Verify: Tests pass.

## Step 5: Profile panel tests

- Empty state before messages: "Start chatting to build your profile...", "0 of 7 fields collected"
- After extraction: business name, services, differentiators populated
- Profile complete: "Your profile is complete!" text + "Build my site" button

Verify: Tests pass.

## Step 6: Mobile profile toggle test

- Before profile exists: no toggle button
- After extraction: toggle button "View Profile" appears (check for `toggle_profile` phx-click)
- Fire toggle event: profile panel becomes visible
- Fire toggle again: panel hidden

Verify: Tests pass.

## Step 7: Provisioning flow tests

- Send message to build complete profile
- Click "provision_site" event
- Verify provisioning state: "Building your site..."
- Send `{:provisioning_complete, %{site_url: "https://test.example.com"}}` to view pid
- Verify "Your site is live!" + link to URL
- Separate test: send `{:provisioning_failed, %{step: :create_company}}` → error message

Verify: Tests pass.

## Step 8: Conversation persistence test

- Mount at /start, send message, wait for streaming
- Get session_id from assigns
- Build new conn with same session_id in session
- Mount at /start again
- Verify previous messages are displayed

Verify: Test passes.

## Step 9: Error recovery tests

- LLM not configured: set `chat_available: false`, mount → redirect to /app/signup
- First message error: set_error, send message, wait → redirect with flash
- Later message error: send 2 messages, simulate error → stays on page with flash

Verify: Tests pass.

## Step 10: Run full test suite

Run `mix test` to ensure no regressions. Verify all new QA tests pass alongside existing chat_live_test.exs tests.

## Testing Strategy

All tests use `Phoenix.LiveViewTest` with `ChatSandbox` for deterministic AI responses. Async operations (streaming, extraction) handled with `Process.sleep/1`. No external service dependencies.
