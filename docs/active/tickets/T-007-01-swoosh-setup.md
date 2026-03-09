---
id: T-007-01
story: S-007
title: swoosh-setup
type: task
status: open
priority: high
phase: done
depends_on: [T-001-06]
---

## Context

Phoenix ships with Swoosh but the generated config needs to be wired to a real provider for production. Configure Swoosh with Postmark (or Resend) as the production adapter, keeping `Swoosh.Adapters.Local` for dev and `Swoosh.Adapters.Test` for test.

## Acceptance Criteria

- `swoosh` and `gen_smtp` (optional local dev) deps confirmed in `mix.exs`
- `Haul.Mailer` module configured with adapter selection via runtime config
- Production adapter reads `POSTMARK_API_KEY` (or `RESEND_API_KEY`) from env
- Dev uses `Swoosh.Adapters.Local` with mailbox viewer at `/dev/mailbox`
- Test uses `Swoosh.Adapters.Test` for assertion-based testing
- Sending a test email works in dev (visible in mailbox viewer)
- No secrets in source — only env var references in `runtime.exs`
