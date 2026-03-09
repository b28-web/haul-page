# T-010-01 Research: fix-booking-crash

## Relevant Files

### Primary
- `lib/haul_web/live/booking_live.ex` — BookingLive module (306 lines)
  - Line 8: `@max_photos 5` module attribute
  - Line 9: `@max_file_size 10_000_000` module attribute
  - Lines 12–29: `mount/3` — sets up socket assigns, calls `allow_upload` with `max_entries: @max_photos`, but does NOT assign `:max_photos` to the socket
  - Line 106: `friendly_error(:too_many_files)` — uses `@max_photos` via compile-time string interpolation (correct, no issue)
  - Line 209: Template label — hardcoded `"Photos of your junk (optional, up to 5)"` instead of using `{@max_photos}`

### Tests
- `test/haul_web/live/booking_live_test.exs` — 11 tests covering rendering, form submission, validation
- `test/haul_web/live/booking_live_upload_test.exs` — upload-specific tests
- All 191 tests pass currently (0 failures)

## Current State

The ticket says `/book` crashes with `KeyError: key :max_photos not found` at line 206 referencing `{@max_photos}`. In the current code, the template uses hardcoded `"up to 5"` text (line 209) rather than `{@max_photos}`. This means either:
1. Someone partially fixed the crash by hardcoding the string, or
2. The ticket describes a state that hasn't yet manifested in production

Regardless, the label is brittle: if `@max_photos` changes, the label text won't update. The fix is to assign `:max_photos` to the socket and reference it dynamically in the template.

## Module Attribute Usage

`@max_photos` is used in three places:
1. `allow_upload :photos, max_entries: @max_photos` — upload config (line 25)
2. `friendly_error(:too_many_files)` — error message (line 106, compile-time interpolation)
3. Template label — should use `{@max_photos}` but currently hardcoded (line 209)

## Constraints

- No other files reference `:max_photos` as a socket assign
- The upload config is the source of truth for the limit
- The module attribute `@max_photos` is the single definition
