# T-007-01 Research: Swoosh Setup

## Current State

### Dependencies (mix.exs)
- `{:swoosh, "~> 1.16"}` — present
- `{:req, "~> 0.5"}` — present (HTTP client for API-based adapters)
- No `gen_smtp` — not needed (ticket says optional)

### Haul.Mailer (lib/haul/mailer.ex)
Minimal module exists:
```elixir
defmodule Haul.Mailer do
  use Swoosh.Mailer, otp_app: :haul
end
```

### Configuration

| File | Setting | Status |
|------|---------|--------|
| config/config.exs | `adapter: Swoosh.Adapters.Local` | ✓ default for all envs |
| config/dev.exs | `config :swoosh, :api_client, false` | ✓ disables HTTP client |
| config/test.exs | `adapter: Swoosh.Adapters.Test` | ✓ assertion-based |
| config/test.exs | `config :swoosh, :api_client, false` | ✓ |
| config/prod.exs | `api_client: Swoosh.ApiClient.Req` | ✓ enables Req for prod |
| config/prod.exs | `local: false` | ✓ disables local storage |
| config/runtime.exs | Mailer section | **COMMENTED OUT** — example uses Mailgun |

### Router (lib/haul_web/router.ex)
- `/dev/mailbox` route exists via `forward "/mailbox", Plug.Swoosh.MailboxPreview`
- Only available when `dev_routes: true` (dev environment)

### Email Sending Points
- `lib/haul/accounts/user.ex` — password reset and magic link senders are stubbed (return `:ok`)
- No notifier modules, no email templates, no Oban workers yet

### Downstream Tickets
- T-007-03 (notifier-oban) depends on this ticket — will add Oban workers for booking notifications
- T-007-04 (notification-templates) — email/SMS content

## Key Findings

1. **90% scaffolded** — Phoenix generator already set up Local/Test adapters, mailbox viewer, and Req client
2. **Only gap: runtime.exs production adapter** — needs Postmark or Resend config with env var
3. **No test email function** — need a way to verify dev setup works (send test email to mailbox)
4. **Swoosh supports Postmark natively** — `Swoosh.Adapters.Postmark` reads `api_key`
5. **Swoosh supports Resend natively** — `Swoosh.Adapters.Resend` reads `api_key`

## Constraints
- No secrets in source code — env vars only in runtime.exs
- Must work without API key in dev/test (Local/Test adapters)
- Production should fail loudly if env var missing
