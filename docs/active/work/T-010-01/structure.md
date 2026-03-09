# T-010-01 Structure: fix-booking-crash

## Files Modified

### `lib/haul_web/live/booking_live.ex`

1. **mount/3** (line 16–28): Add `|> assign(:max_photos, @max_photos)` to the socket pipeline
2. **render/1 template** (line 209): Change hardcoded label from `"Photos of your junk (optional, up to 5)"` to `"Photos of your junk (optional, up to {@max_photos})"`

### `test/haul_web/live/booking_live_test.exs`

1. **rendering describe block**: Add test asserting the photo upload label displays the correct max count (verifies dynamic assign works)

## Files Created

None.

## Files Deleted

None.

## Module Boundaries

No new modules. No interface changes. The only change is adding one socket assign and updating one template string.

## Change Ordering

1. Fix `booking_live.ex` (both mount and template)
2. Add test
3. Run full suite
