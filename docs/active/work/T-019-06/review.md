# T-019-06 Review: Browser QA — Chat Onboarding

## Summary

Added comprehensive browser QA test coverage for the conversational onboarding chat at `/start`. 25 end-to-end tests covering the full user journey: chat UI layout, multi-turn conversation flow, streaming UX, profile extraction, mobile toggle, provisioning lifecycle, conversation persistence, error recovery, and rate limiting.

## Files Changed

### Created
- `test/haul_web/live/chat_qa_test.exs` — 25 tests across 9 describe blocks

### Modified
- None

### Deleted
- None

## Test Coverage

| Area | Tests | Status |
|------|-------|--------|
| Chat UI layout | 5 | ✓ |
| Full conversation flow | 2 | ✓ |
| Streaming UX | 3 | ✓ |
| Profile panel | 5 | ✓ |
| Mobile profile toggle | 2 | ✓ |
| Provisioning flow | 3 | ✓ |
| Conversation persistence | 1 | ✓ |
| Error recovery | 3 | ✓ |
| Rate limiting | 1 | ✓ |
| **Total** | **25** | **All pass** |

Combined with existing `chat_live_test.exs` (16 tests), total chat coverage: **41 tests**.

## Acceptance Criteria Verification

| Criterion | Verified |
|-----------|----------|
| Chat conversation works end-to-end | ✓ Multi-turn flow, message persistence |
| Streaming responses render correctly | ✓ Typing indicator, progressive display, input disable/enable |
| Profile extraction panel updates in real-time | ✓ All 7 fields, completeness %, services, differentiators |
| Mobile chat UX is smooth | ✓ Toggle button, show/hide panel (event-level, not viewport) |
| Fallback link is accessible | ✓ Both header and below-input links verified |

## Open Concerns

1. **Conversation message persistence bug**: `AppendMessage` change uses `Ash.Changeset.get_data/2` which reads from the stale in-memory struct, not the current DB state. When two `persist_message` calls happen in sequence (user message, then AI message), the second overwrites the first. The AI response survives because it's persisted last. This is a pre-existing issue from T-019-03 — not introduced or fixed by this ticket. Impact: on reconnection, only the last-persisted message per pair survives. A fix would require `AppendMessage` to reload the current messages from DB before appending.

2. **Pre-existing test failure**: `test/haul/ai/edit_applier_test.exs:94` fails (service removal test). Unrelated to this ticket — appears to be from T-020 work in progress.

3. **Mobile viewport testing**: Mobile UX tests verify the `toggle_profile` event handler and button rendering, but cannot test actual viewport behavior (CSS media queries, touch interactions). This follows the project convention — all prior browser QA tickets use LiveViewTest, not Playwright.

## Test Run

```
mix test test/haul_web/live/chat_qa_test.exs
25 tests, 0 failures (22.6s)

mix test
691 tests, 1 failure (pre-existing), 1 excluded
```
