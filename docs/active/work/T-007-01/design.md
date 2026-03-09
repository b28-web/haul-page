# T-007-01 Design: Swoosh Setup

## Decision: Postmark as Primary Production Adapter

### Options Evaluated

**Option A: Postmark (chosen)**
- Swoosh has `Swoosh.Adapters.Postmark` built-in
- Single env var: `POSTMARK_API_KEY`
- Industry standard for transactional email
- Excellent deliverability for booking confirmations
- Matches ticket AC which lists Postmark first

**Option B: Resend**
- Swoosh has `Swoosh.Adapters.Resend` built-in
- Single env var: `RESEND_API_KEY`
- Newer service, good DX
- Also viable but ticket prefers Postmark

**Option C: Mailgun (rejected)**
- Already in commented example — but not mentioned in AC
- Requires both API key and domain

### Decision
Use **Postmark** as the default production adapter with fallback support for Resend. The runtime.exs will check for `POSTMARK_API_KEY` first, then `RESEND_API_KEY`, raising if neither is set in production.

### Adapter Selection Logic (runtime.exs)
```
if POSTMARK_API_KEY set → use Swoosh.Adapters.Postmark
elif RESEND_API_KEY set → use Swoosh.Adapters.Resend
elif prod → raise "Must set POSTMARK_API_KEY or RESEND_API_KEY"
```

### Test Email Verification
Add a Mix task `mix haul.test_email` that sends a test email via `Haul.Mailer` — visible in `/dev/mailbox` during dev. This satisfies AC: "Sending a test email works in dev."

### What We're NOT Doing
- No email templates (T-007-04)
- No Oban workers (T-007-03)
- No auth email integration (separate ticket)
- No gen_smtp dep (AC says optional, not needed for API adapters)
