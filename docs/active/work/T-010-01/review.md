# T-010-01 Review: fix-booking-crash

## Summary

Fixed the booking page photo upload label to dynamically display the max photo count from the socket assign instead of a hardcoded value. Added the missing `:max_photos` socket assign to `mount/3`.

## Files Modified

| File | Change |
|------|--------|
| `lib/haul_web/live/booking_live.ex` | Added `assign(:max_photos, @max_photos)` to mount pipeline; changed template label to use `{@max_photos}` |
| `test/haul_web/live/booking_live_test.exs` | Added test verifying photo upload label displays correct max count |

## Files Created

None (only work artifacts in `docs/active/work/T-010-01/`).

## Test Coverage

- **New test:** "shows photo upload label with max count" — verifies the dynamic label renders correctly
- **Existing tests:** All 191 existing tests continue to pass
- **Total:** 192 tests, 0 failures
- **Coverage gap:** None identified for this change

## Acceptance Criteria Verification

- `/book` renders the booking form without errors — **PASS** (verified by tests)
- Photo upload label displays correct max count — **PASS** (dynamic `{@max_photos}` renders "up to 5")
- `mix test` passes — **PASS** (192 tests, 0 failures)

## Open Concerns

None. This was a minimal, targeted fix with no side effects.

## Notes

The ticket described a `KeyError: key :max_photos not found` crash, but the current codebase had a hardcoded "up to 5" string instead of `{@max_photos}` in the template. The fix adds the socket assign and uses it dynamically, preventing both the described crash scenario and future drift between the upload config and the label text.
