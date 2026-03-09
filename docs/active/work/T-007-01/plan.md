# T-007-01 Plan: Swoosh Setup

## Steps

### Step 1: Configure runtime.exs production adapter
- Replace commented mailer section with Postmark/Resend adapter selection
- Read env vars, raise in prod if missing
- Verify: `mix compile` succeeds

### Step 2: Add test_email helper to Haul.Mailer
- Add `test_email/1` function that builds a Swoosh.Email struct
- Takes recipient email, returns `{:ok, _}` or `{:error, _}`
- Verify: `mix compile` succeeds

### Step 3: Create Mix task for dev email testing
- `mix haul.test_email` — sends test email via Haul.Mailer
- Uses operator email from config as default recipient
- Verify: task appears in `mix help`

### Step 4: Write tests
- Test `Haul.Mailer.test_email/1` builds correct struct and delivers
- Use `Swoosh.Adapters.Test` (already configured)
- Verify: `mix test test/haul/mailer_test.exs`

### Step 5: Verify full test suite
- `mix test` — all existing tests still pass
- No regressions from config changes

## Testing Strategy
- Unit test: email struct correctness (to, from, subject, body)
- Integration test: delivery via Test adapter with `assert_email_sent`
- Manual verification: `mix haul.test_email` in dev → visible at `/dev/mailbox`
