# T-017-02 Research: Cert Provisioning

## Ticket Requirements

Automate TLS certificate provisioning for custom domains via Fly.io API:
- Oban worker: `Haul.Workers.ProvisionCert`
- On DNS verification success, enqueue cert provisioning job
- Call Fly.io API: `fly certs add <domain>` equivalent via REST API
- Poll for cert readiness (Let's Encrypt — seconds to minutes)
- On success: update Company `domain_verified_at`, set domain_status to :active
- On failure: retry with exponential backoff, notify operator after 3 failures
- Domain removal: Oban worker calls `fly certs remove` equivalent
- Fly API token stored as env var (platform-level)

## Codebase Analysis

### Company Resource (`lib/haul/accounts/company.ex`)
- Has `domain` (string, nullable) and `domain_status` (atom: pending/verified/provisioning/active)
- `update_company` action accepts both fields
- **Missing:** `domain_verified_at` (utc_datetime) — needs migration or repurpose of existing flow
- Identity on `:unique_domain` prevents duplicate domains

### Domain Settings UI (`lib/haul_web/live/app/domain_settings_live.ex`)
- 4 UI states: upgrade prompt, add domain form, pending verification, provisioning, active
- DNS verification flow: user clicks "Verify DNS" → calls `Domains.verify_dns/2` → sets status to `:verified`
- Domain removal: sets domain=nil, domain_status=nil
- **Integration point:** After DNS verify succeeds, should enqueue ProvisionCert and set status to `:provisioning`
- **Integration point:** On domain removal, should enqueue ProvisionCert with `:remove` action

### Domains Module (`lib/haul/domains.ex`)
- `normalize_domain/1`, `valid_domain?/1`, `verify_dns/2`
- DNS verification uses `:inet_res.lookup/3` for CNAME records
- Pure utility module — no Oban or API calls

### Oban Configuration (`config/config.exs`)
- Queues: `notifications: 10, default: 5`
- Plugins: Cron for CheckDunningGrace
- Need to add `certs` queue

### Existing Workers
- `SendBookingEmail`, `SendBookingSMS` — queue: :notifications, max_attempts: 3
- `CheckDunningGrace` — queue: :default, cron-scheduled, queries companies then acts

### HTTP Client
- `Req` already in deps (used by Places.Google, SMS.Twilio)
- Pattern: `Req.post(url, json: body, headers: headers)` → match on `%Req.Response{status: ..., body: ...}`

### Adapter Pattern (Billing)
- `Haul.Billing` — behaviour with callbacks, adapter dispatch via `Application.get_env`
- `Haul.Billing.Stripe` (prod) / `Haul.Billing.Sandbox` (dev/test)
- Config in runtime.exs: `config :haul, :billing_adapter, Haul.Billing.Stripe`

### Notification Emails
- `Haul.Notifications.BillingEmail.payment_failed/1` — Swoosh email builder
- Pattern: `new() |> to(...) |> from(...) |> subject(...) |> text_body(...)`

### Runtime Config (`config/runtime.exs`)
- External services configured via env vars (STRIPE_SECRET_KEY, TWILIO_ACCOUNT_SID, etc.)
- Pattern: `if env_var = System.get_env("KEY") do config :haul, ... end`

## Fly.io Machines API

The Fly.io Machines API (v1) handles certificates:
- **Base URL:** `https://api.machines.dev/v1`
- **Auth:** Bearer token via `FLY_API_TOKEN`
- **Add cert:** `POST /apps/{app_name}/certificates` with `{"hostname": "domain.com"}`
- **Check cert:** `GET /apps/{app_name}/certificates/{hostname}`
- **Remove cert:** `DELETE /apps/{app_name}/certificates/{hostname}`
- Certificate provisioning is async — returns immediately, Let's Encrypt handles issuance

## Key Constraints

1. Single Fly app for all tenants (multi-tenant) — cert ops use platform-level app name
2. Fly API token is a platform secret, not per-operator
3. Cert provisioning can take seconds to minutes — need polling strategy
4. Need to handle: API down, rate limits, Let's Encrypt failures
5. Domain removal must clean up cert on Fly side
6. Company needs `domain_verified_at` timestamp (AC requirement)

## Files That Need Changes

- **Create:** `lib/haul/domains/fly_api.ex` — HTTP client for Fly cert API
- **Create:** `lib/haul/domains/sandbox.ex` — Test/dev adapter
- **Create:** `lib/haul/workers/provision_cert.ex` — Oban worker
- **Create:** `lib/haul/notifications/domain_email.ex` — Failure notification
- **Create:** `test/haul/workers/provision_cert_test.exs` — Worker tests
- **Modify:** `lib/haul/domains.ex` — Add adapter dispatch for cert operations
- **Modify:** `lib/haul_web/live/app/domain_settings_live.ex` — Enqueue job on verify/remove
- **Modify:** `config/config.exs` — Add certs queue, cert_adapter default
- **Modify:** `config/runtime.exs` — FLY_API_TOKEN, FLY_APP_NAME config
- **Modify:** `lib/haul/accounts/company.ex` — Add domain_verified_at attribute
- **Create:** Migration for domain_verified_at
