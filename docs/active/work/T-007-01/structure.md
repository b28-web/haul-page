# T-007-01 Structure: Swoosh Setup

## Files Modified

### config/runtime.exs
- Uncomment and replace mailer section
- Add adapter selection: Postmark (primary) or Resend (fallback)
- Read `POSTMARK_API_KEY` or `RESEND_API_KEY` from env
- Raise in prod if neither is set

### lib/haul/mailer.ex
- Keep existing `use Swoosh.Mailer, otp_app: :haul`
- Add `test_email/1` convenience function for dev verification

## Files Created

### lib/mix/tasks/haul.test_email.ex
- Mix task `mix haul.test_email`
- Builds a simple Swoosh.Email and delivers via Haul.Mailer
- For dev use: email shows up in `/dev/mailbox`

### test/haul/mailer_test.exs
- Test that `Haul.Mailer.test_email/1` builds correct email struct
- Test that delivery works with Test adapter (assertion-based)

## Files Unchanged
- config/config.exs — Local adapter default already correct
- config/dev.exs — api_client false already correct
- config/test.exs — Test adapter already correct
- config/prod.exs — Req client + local false already correct
- mix.exs — swoosh + req deps already present
- lib/haul_web/router.ex — /dev/mailbox already wired

## Module Boundaries
- `Haul.Mailer` — Swoosh mailer + test_email helper
- `Mix.Tasks.Haul.TestEmail` — dev-only mix task
- No new domains, no new Ash resources
