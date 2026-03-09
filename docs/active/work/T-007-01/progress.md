# T-007-01 Progress: Swoosh Setup

## Completed

### Step 1: Configure runtime.exs production adapter ✓
- Replaced commented Mailgun example with Postmark/Resend adapter selection
- Uses `cond` to check `POSTMARK_API_KEY` first, then `RESEND_API_KEY`
- Raises with clear message if neither is set in production

### Step 2: Add test_email helper to Haul.Mailer ✓
- Added `test_email/1` function that builds and delivers a Swoosh.Email
- Uses operator config for from name/email
- Returns `{:ok, _}` or `{:error, _}`

### Step 3: Create Mix task ✓
- `mix haul.test_email [recipient]` — sends test email
- Defaults to operator email if no argument given
- Created at `lib/mix/tasks/haul/test_email.ex`

### Step 4: Write tests ✓
- 2 tests in `test/haul/mailer_test.exs`
- Tests delivery and operator config usage
- Both pass with `Swoosh.Adapters.Test`

### Step 5: Full test suite ✓
- 134 tests total (130 pass, 4 pre-existing failures)
- Pre-existing failures: ScanLive gallery (2), QR controller (1), booking upload (1)
- No regressions from this ticket's changes

## Deviations from Plan
None.
