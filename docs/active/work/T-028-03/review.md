# T-028-03 Review: Extract LiveView Logic

## Summary

Extracted 22 pure functions from 11 LiveView modules into 5 focused helper modules. Eliminated 4 cross-module duplications (get_field ×4, friendly_error ×3, format_price ×2, reorder ×3). Added 69 unit tests.

## Files Created (5 modules + 5 test files)

| File | Purpose |
|------|---------|
| `lib/haul_web/helpers.ex` | Shared view utilities: get_field, friendly_upload_error, merge_preferred_dates |
| `lib/haul/formatting.ex` | Display formatting: plan_rank/name/price/badge, format_amount, star_display, source_label, days_until_downgrade |
| `lib/haul/ai/message.ex` | Chat message manipulation: build_transcript, append_to_last_assistant, has_assistant_content?, deep_to_map, restore_messages |
| `lib/haul/sortable.ex` | Reorder helpers: find_swap_index, next_sort_order |
| `lib/haul/admin/account_helpers.ex` | Admin list operations: filter_companies, sort_companies, toggle_dir, sort_indicator |
| `test/haul_web/helpers_test.exs` | 14 tests |
| `test/haul/formatting_test.exs` | 24 tests |
| `test/haul/ai/message_test.exs` | 18 tests |
| `test/haul/sortable_test.exs` | 9 tests |
| `test/haul/admin/account_helpers_test.exs` | 14 tests (including sort by DateTime) |

## Files Modified (11 LiveView modules + 1 controller)

| File | Changes |
|------|---------|
| `lib/haul_web/live/scan_live.ex` | Removed get_field, import HaulWeb.Helpers |
| `lib/haul_web/controllers/page_controller.ex` | Removed get_field, import HaulWeb.Helpers |
| `lib/haul_web/live/booking_live.ex` | Removed get_field, friendly_error, merge_preferred_dates; import helpers |
| `lib/haul_web/live/payment_live.ex` | Removed get_field, format_amount; import helpers |
| `lib/haul_web/live/app/gallery_live.ex` | Removed friendly_error, next_sort_order; simplified reorder with Sortable |
| `lib/haul_web/live/app/services_live.ex` | Simplified reorder with Sortable |
| `lib/haul_web/live/app/endorsements_live.ex` | Removed source_label, star_display, simplified reorder; import Formatting |
| `lib/haul_web/live/app/billing_live.ex` | Removed plan_rank, plan_name, format_price, days_until_downgrade; import Formatting |
| `lib/haul_web/live/chat_live.ex` | Removed build_transcript, append_to_last_assistant, has_assistant_content?, deep_to_map, restore_messages; delegate to AI.Message |
| `lib/haul_web/live/app/onboarding_live.ex` | Removed upload_error_to_string; import helpers |
| `lib/haul_web/live/admin/accounts_live.ex` | Removed filter/sort/toggle/indicator/badge; import helpers |

## Test Coverage

- **69 new unit tests** (all `async: true`) — exceeds 20+ target
- **961 total tests, 0 failures** — all existing integration tests pass unchanged
- Test count increase: 845 → 961 (+116, includes tests from other concurrent tickets)

## Duplications Eliminated

| Pattern | Was | Now |
|---------|-----|-----|
| `get_field/2` | 4 copies in 4 files | 1 in HaulWeb.Helpers |
| Upload error formatting | 3 copies, slightly different msgs | 1 in HaulWeb.Helpers |
| Price formatting (cents→$) | 2 copies (format_price, format_amount) | 2 functions in Haul.Formatting |
| Reorder swap logic | 3 identical ~30-line blocks | 3 calls to Sortable.find_swap_index |

## Design Decisions

1. **Sortable only does pure index calculation** — Ash.update! calls stay in LiveViews since they're side effects requiring tenant context
2. **AIMessage aliased as `AIMessage`** — avoids conflict with potential Ecto schema
3. **step_title stayed in OnboardingLive** — 6 lines, single use, not worth extracting
4. **friendly_upload_error uses generic messages** — "File is too large" instead of "File is too large (max 5MB)" since max varies by context. LiveViews can append context if needed.

## Open Concerns

- **friendly_upload_error generic messages**: The consolidated error messages are more generic than the originals (e.g., no max size in the message). This is intentional — the size limit varies (5MB gallery, 10MB booking) — but could be surprising if someone expects the exact old text.
- **ChatLive all_profile_fields/0**: Left in ChatLive since it's only used there and is a simple list constant. Could move to Extractor module if reuse emerges.

## Acceptance Criteria Check

- [x] Extract 8-12 pure functions from LiveView modules → **22 functions extracted**
- [x] Each extracted function has unit tests (ExUnit.Case, async: true) → **69 tests, all async**
- [x] LiveView handle_event/3 callbacks become thin dispatchers → **Done for all modified files**
- [x] Existing LiveView integration tests still pass unchanged → **961 tests, 0 failures**
- [x] Net new test count: 20+ unit tests added → **69 new tests**
