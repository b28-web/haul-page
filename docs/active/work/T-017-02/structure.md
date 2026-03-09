# T-017-02 Structure: Cert Provisioning

## Files to Create

### `lib/haul/domains/fly_api.ex`
Production adapter for Fly.io certificate API.
- `@behaviour Haul.Domains.CertAdapter`
- `add_cert(domain)` — POST to Fly API
- `check_cert(domain)` — GET from Fly API, return :ready | :pending | {:error, reason}
- `remove_cert(domain)` — DELETE from Fly API
- Uses `Req` for HTTP, Bearer token auth
- Reads app_name and api_token from config

### `lib/haul/domains/sandbox.ex`
Dev/test adapter — returns canned success responses.
- `@behaviour Haul.Domains.CertAdapter`
- `add_cert/1` → `{:ok, %{status: "pending"}}`
- `check_cert/1` → `{:ok, :ready}`
- `remove_cert/1` → `:ok`

### `lib/haul/workers/provision_cert.ex`
Oban worker for cert provisioning.
- `use Oban.Worker, queue: :certs, max_attempts: 3`
- `perform/1` dispatches on `args["action"]`: "add" or "remove"
- Add flow: call adapter add_cert, poll check_cert in loop, update company
- Remove flow: call adapter remove_cert (best-effort)
- On final failure (attempt >= max_attempts): send notification email
- Broadcasts PubSub on status change

### `lib/haul/notifications/domain_email.ex`
Email template for cert provisioning failure.
- `cert_failed(company, domain)` — Swoosh email to operator

### `test/haul/workers/provision_cert_test.exs`
Tests for the worker with sandbox adapter.
- Test add flow: company gets domain_status=:active, domain_verified_at set
- Test remove flow: cert removed (sandbox returns :ok)
- Test final failure notification

### `priv/repo/migrations/20260309080000_add_domain_verified_at_to_companies.exs`
Migration adding `domain_verified_at` utc_datetime column to companies.

## Files to Modify

### `lib/haul/domains.ex`
Add cert adapter behaviour and dispatch functions.
- Define `@callback` for add_cert, check_cert, remove_cert
- Add `add_cert/1`, `check_cert/1`, `remove_cert/1` public functions
- Private `cert_adapter/0` reads from config

### `lib/haul/accounts/company.ex`
Add `domain_verified_at` attribute (utc_datetime, nullable).
Update `update_company` action to accept it.

### `lib/haul_web/live/app/domain_settings_live.ex`
- In `handle_event("verify_dns")` success path: set domain_status to :provisioning, enqueue ProvisionCert
- In `handle_event("confirm_remove")`: enqueue ProvisionCert remove before clearing domain
- On mount: subscribe to PubSub topic `"domain:#{company.id}"`
- Add `handle_info` for PubSub broadcasts to refresh domain_status

### `config/config.exs`
- Add `certs: 3` to Oban queues
- Add `config :haul, :cert_adapter, Haul.Domains.Sandbox`

### `config/runtime.exs`
- Add FLY_API_TOKEN + FLY_APP_NAME config block
- When present, set `config :haul, :cert_adapter, Haul.Domains.FlyApi`

## Module Boundaries

```
Haul.Domains (public API)
├── normalize_domain/1, valid_domain?/1, verify_dns/2  (existing)
├── add_cert/1, check_cert/1, remove_cert/1  (new — delegates to adapter)
├── Haul.Domains.FlyApi  (production adapter)
└── Haul.Domains.Sandbox  (dev/test adapter)

Haul.Workers.ProvisionCert (Oban worker)
├── Uses Haul.Domains for cert operations
├── Uses Haul.Accounts.Company for status updates
├── Uses Haul.Notifications.DomainEmail for failure alerts
└── Uses Phoenix.PubSub for real-time UI updates

HaulWeb.App.DomainSettingsLive (UI)
├── Enqueues ProvisionCert jobs
└── Subscribes to PubSub for status updates
```

## Ordering

1. Migration + Company attribute (foundation)
2. Domains module updates (adapter behaviour + dispatch)
3. Sandbox adapter (enables testing)
4. FlyApi adapter (production implementation)
5. DomainEmail (notification)
6. ProvisionCert worker (core logic)
7. LiveView integration (UI hooks)
8. Config updates (queues + runtime)
9. Tests
