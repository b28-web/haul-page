# T-010-01 Progress: fix-booking-crash

## Completed

1. Added `assign(:max_photos, @max_photos)` to `mount/3` in BookingLive
2. Changed template label from hardcoded "up to 5" to dynamic `{@max_photos}`
3. Added test "shows photo upload label with max count" in booking_live_test.exs
4. Full test suite: 192 tests, 0 failures

## Deviations from Plan

None. All steps executed as planned.
