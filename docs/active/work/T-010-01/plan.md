# T-010-01 Plan: fix-booking-crash

## Steps

### Step 1: Add `:max_photos` assign to mount/3
- In `lib/haul_web/live/booking_live.ex`, add `|> assign(:max_photos, @max_photos)` to the socket pipeline in mount
- Place it after the existing assigns, before `allow_upload`

### Step 2: Update template label to use dynamic assign
- Change line 209 from hardcoded "up to 5" to `"up to {@max_photos}"`

### Step 3: Add test for photo upload label
- In `test/haul_web/live/booking_live_test.exs`, add a test in the "rendering" describe block
- Assert that rendered HTML contains "up to 5" (verifying the dynamic label)

### Step 4: Run full test suite
- `mix test` — expect all tests to pass (191 existing + 1 new = 192)

### Step 5: Commit
- Single atomic commit covering the fix and test

## Verification Criteria
- `/book` renders without error
- Photo upload label displays "up to 5" dynamically
- `mix test` passes with 0 failures
