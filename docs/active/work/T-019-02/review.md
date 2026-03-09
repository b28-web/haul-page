# T-019-02 Review: Live Extraction

## Summary of Changes

### Files Modified
| File | Change | Lines |
|------|--------|-------|
| `lib/haul_web/live/chat_live.ex` | Added extraction logic, profile panel UI, debounce timer, new assigns | ~260 lines added (integrated with T-019-03 persistence additions) |
| `test/haul_web/live/chat_live_test.exs` | Added 8 new tests in "live extraction" describe block | ~80 lines added |

### No New Files Created
All extraction infrastructure (Extractor, OperatorProfile, AI adapters) was already in place from T-018-03.

## Acceptance Criteria Coverage

| Criterion | Status | Notes |
|-----------|--------|-------|
| Run extraction after each user message | Done | `schedule_extraction/1` called in `send_user_message/2` |
| Profile panel (sidebar desktop, card mobile) | Done | 2-column flex layout, mobile toggle button |
| Shows fields filled or "not yet provided" | Done | `profile_field/1` component with conditional styling |
| Services list with categories | Done | Renders service names from OperatorProfile.services |
| Completeness indicator with progress bar | Done | "X of 7 fields collected" + animated progress bar |
| Profile updates animate | Done | `transition-colors duration-300` on fields, `transition-all duration-500` on progress bar |
| Extraction runs async | Done | Spawned in Task, doesn't block chat streaming |
| "Your profile is complete!" CTA | Done | Shows when business_name + phone + email present |
| Extraction errors silent to user | Done | Logged via `Logger.warning`, no flash or UI error |
| Debounce rapid messages | Done | 800ms timer, cancel-and-reschedule pattern |

## Test Coverage

**17 tests total, 0 failures** (8 new + 9 existing)

New tests:
1. `profile panel updates after extraction completes` — verifies profile data renders
2. `completeness indicator updates with extracted fields` — checks "7 of 7" text
3. `services list renders in profile panel` — checks service names appear
4. `differentiators render in profile panel` — checks differentiator text
5. `profile complete CTA appears` — checks "Your profile is complete!" and "Create my site"
6. `extraction errors do not show in UI` — sends error message, verifies no error text
7. `extraction crash is handled silently` — sends DOWN message, verifies no crash
8. `profile sidebar with empty state` — checks initial state renders correctly

### Test Gaps
- **Debounce timing not directly tested** — Would require precise timing control. Covered implicitly by the fact that extraction works after a single message send + sleep.
- **Mobile toggle not tested** — Would need JS/viewport simulation. Functional logic (assign toggle) is simple enough to trust.
- **Concurrent extraction + streaming** — Not explicitly tested in isolation, but covered by the fact that all message-send tests trigger both streaming and extraction simultaneously.

## Architecture Decisions

1. **Function components, not LiveComponents** — Profile panel is tightly coupled to chat state. No benefit from LiveComponent boundary.
2. **800ms debounce** — Balances responsiveness with API load. User typing rapidly won't trigger multiple extractions.
3. **Separate task refs** — `task_ref` for chat streaming, `extraction_ref` for extraction. Both tracked independently in `{:DOWN}` handler.
4. **7 trackable fields** — business_name, owner_name, phone, email, service_area, services, differentiators. Completeness = filled / 7.
5. **Required fields for "complete"** — business_name + phone + email (from ProfileMapper.missing_fields). Service area and services checked by validate_completeness but not required for CTA.

## Open Concerns

1. **T-019-03 Jason.Encoder issue** — The `save_extracted_profile` function (added by T-019-03) fails because `OperatorProfile.ServiceOffering` doesn't derive `Jason.Encoder`. This is logged as a warning and doesn't affect extraction display. The fix is simple (`@derive Jason.Encoder` on ServiceOffering) but belongs to T-019-03.

2. **Sandbox adapter limitation** — Tests always get the default Sandbox response (complete profile) because extraction runs in a Task and process-dict overrides don't propagate. This means tests can't verify partial profiles or specific field values. The existing extractor tests in `test/haul/ai/extractor_test.exs` cover those cases.

3. **"Create my site" link** — Currently points to `/app/onboarding`. This route may not exist yet (depends on T-015-02 onboarding wizard). Link target may need adjustment when that ticket is implemented.

4. **Pre-existing test suite failures** — 318 failures in full suite from migration issues and incomplete work from other tickets. ChatLive's 17 tests all pass in isolation.
