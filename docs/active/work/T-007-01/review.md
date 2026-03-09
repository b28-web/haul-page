# T-007-01 Review: Swoosh Setup

## Summary

Configured Swoosh for production use with Postmark (primary) or Resend (fallback) adapters. Added a test email helper and Mix task for dev verification. All acceptance criteria met.

## Files Modified

| File | Change |
|------|--------|
| `config/runtime.exs` | Replaced commented Mailgun example with Postmark/Resend `cond` block |
| `lib/haul/mailer.ex` | Added `test_email/1` function using operator config |

## Files Created

| File | Purpose |
|------|---------|
| `lib/mix/tasks/haul/test_email.ex` | `mix haul.test_email` — sends test email for dev verification |
| `test/haul/mailer_test.exs` | 2 tests: delivery + operator config |

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| swoosh dep in mix.exs | ✓ Already present (`~> 1.16`) |
| Haul.Mailer configured with adapter selection | ✓ runtime.exs selects Postmark or Resend |
| Production reads POSTMARK_API_KEY or RESEND_API_KEY | ✓ `cond` block in runtime.exs |
| Dev uses Swoosh.Adapters.Local | ✓ config/config.exs (unchanged, already correct) |
| Dev mailbox at /dev/mailbox | ✓ router.ex (unchanged, already wired) |
| Test uses Swoosh.Adapters.Test | ✓ config/test.exs (unchanged, already correct) |
| Test email works in dev | ✓ `mix haul.test_email` sends to /dev/mailbox |
| No secrets in source | ✓ Only env var references in runtime.exs |

## Test Coverage

- **New tests:** 2 (both pass)
- **Total suite:** 134 tests, 4 pre-existing failures unrelated to this ticket
- **Pre-existing failures:** ScanLive gallery rendering (2), QR controller size clamp (1), booking upload (1)

## Open Concerns

1. **gen_smtp not added** — AC says "optional". Not needed since we use API-based adapters (Postmark/Resend), not SMTP. Can add later if needed.
2. **No email templates yet** — T-007-04 will handle booking confirmation templates.
3. **Auth email senders still stubbed** — `lib/haul/accounts/user.ex` has TODO comments for password reset and magic link emails. Separate from this ticket.
4. **Pre-existing test failures** — 4 tests fail before and after this change. Tracked in S-010 bugfix story.
