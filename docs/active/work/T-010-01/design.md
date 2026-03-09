# T-010-01 Design: fix-booking-crash

## Problem

The photo upload label in BookingLive hardcodes "up to 5" instead of dynamically using the `@max_photos` module attribute. This is brittle — if the limit changes, the label drifts. The ticket describes a crash scenario where `{@max_photos}` is used in the template without a corresponding socket assign.

## Options

### Option A: Add `:max_photos` socket assign + use in template
- Add `assign(:max_photos, @max_photos)` to `mount/3`
- Change label from `"Photos of your junk (optional, up to 5)"` to `"Photos of your junk (optional, up to {@max_photos})"`
- **Pros:** DRY, prevents drift, matches ticket's prescribed fix
- **Cons:** None

### Option B: Keep hardcoded, just document
- Leave "up to 5" hardcoded, add a comment noting it must match `@max_photos`
- **Pros:** Zero code change
- **Cons:** Still brittle, doesn't address the ticket

### Option C: Use module attribute in template via sigil interpolation
- HEEx templates can reference module attributes directly via `@max_photos` in compile-time expressions, but in HEEx `{@max_photos}` means a socket assign. Module attributes require compile-time evaluation.
- **Pros:** No socket assign needed
- **Cons:** Not how HEEx works — `{@var}` in templates always means socket assigns

## Decision

**Option A.** Add the socket assign and use it in the template. This is the simplest, most correct fix. It makes the label dynamic and eliminates the possibility of drift.

## Test Strategy

- Existing test "GET /book renders the booking form" already verifies the page loads without error
- Add an assertion that the rendered HTML contains "up to 5" to verify the dynamic label works
- Run full test suite to confirm no regressions
