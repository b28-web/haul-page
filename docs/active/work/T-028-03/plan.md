# T-028-03 Plan: Implementation Steps

## Step 1: Create HaulWeb.Helpers + tests
- Create `lib/haul_web/helpers.ex` with `get_field/2`, `friendly_upload_error/1`, `merge_preferred_dates/1`
- Create `test/haul_web/helpers_test.exs` — test all 3 functions
- Run: `mix test test/haul_web/helpers_test.exs`

## Step 2: Create Haul.Formatting + tests
- Create `lib/haul/formatting.ex` with all formatting functions
- Create `test/haul/formatting_test.exs` — test each function
- Run: `mix test test/haul/formatting_test.exs`

## Step 3: Create Haul.AI.Message + tests
- Create `lib/haul/ai/message.ex` with transcript/append/content/deep_to_map/restore
- Create `test/haul/ai/message_test.exs`
- Run: `mix test test/haul/ai/message_test.exs`

## Step 4: Create Haul.Sortable + tests
- Create `lib/haul/sortable.ex` with find_swap_index/next_sort_order
- Create `test/haul/sortable_test.exs`
- Run: `mix test test/haul/sortable_test.exs`

## Step 5: Create Haul.Admin.AccountHelpers + tests
- Create `lib/haul/admin/account_helpers.ex` with filter/sort/toggle/indicator
- Create `test/haul/admin/account_helpers_test.exs`
- Run: `mix test test/haul/admin/account_helpers_test.exs`

## Step 6: Rewire LiveViews — get_field dedup
- Update BookingLive, PaymentLive, ScanLive to use HaulWeb.Helpers.get_field/2
- Update PageController to use HaulWeb.Helpers.get_field/2
- Run: `mix test test/haul_web/live/booking_live_test.exs test/haul_web/live/payment_live_test.exs test/haul_web/live/scan_live_test.exs test/haul_web/controllers/page_controller_test.exs`

## Step 7: Rewire LiveViews — upload errors dedup
- Update BookingLive, GalleryLive, OnboardingLive to use HaulWeb.Helpers.friendly_upload_error/1
- Run: `mix test test/haul_web/live/booking_live_test.exs test/haul_web/live/app/gallery_live_test.exs test/haul_web/live/app/onboarding_live_test.exs`

## Step 8: Rewire BillingLive + PaymentLive — formatting
- Replace BillingLive's plan_rank/plan_name/format_price/days_until_downgrade with Haul.Formatting calls
- Replace PaymentLive's format_amount with Haul.Formatting call
- Run: `mix test test/haul_web/live/app/billing_live_test.exs test/haul_web/live/payment_live_test.exs`

## Step 9: Rewire ChatLive — message helpers
- Replace ChatLive's transcript/append/content/deep_to_map/restore with Haul.AI.Message calls
- Run: `mix test test/haul_web/live/chat_live_test.exs` (if exists, else booking_live tests)

## Step 10: Rewire Gallery/Services/Endorsements — sortable + formatting
- Simplify reorder logic in all 3 LiveViews using Haul.Sortable
- Move source_label, star_display calls to Haul.Formatting
- Move extract_key, next_sort_order to use Sortable/Formatting
- Run: `mix test test/haul_web/live/app/gallery_live_test.exs test/haul_web/live/app/services_live_test.exs test/haul_web/live/app/endorsements_live_test.exs`

## Step 11: Rewire AccountsLive — admin helpers
- Replace filter/sort/toggle/indicator/badge with Haul.Admin.AccountHelpers + Haul.Formatting calls
- Run: `mix test test/haul_web/live/admin/`

## Step 12: Rewire BookingLive — merge_preferred_dates
- Replace BookingLive's merge_preferred_dates with HaulWeb.Helpers call
- Run: `mix test test/haul_web/live/booking_live_test.exs`

## Step 13: Full test suite
- Run: `mix test`
- Verify 0 failures, note test count increase
- Count net new tests (target: 20+)

## Verification
- All existing LiveView integration tests pass unchanged
- New unit tests pass with `async: true`
- Each extracted function is called from its original LiveView (no dead code)
- No socket/process references in extracted modules
