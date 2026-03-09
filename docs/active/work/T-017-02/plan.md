# T-017-02 Plan: Cert Provisioning

## Step 1: Migration + Company Attribute

- Create migration `20260309080000_add_domain_verified_at_to_companies.exs`
- Add `domain_verified_at :utc_datetime` to Company resource
- Add to `update_company` accept list
- Run migration
- Verify: `mix test test/haul/accounts/company_test.exs`

## Step 2: Domains Module — Adapter Behaviour + Dispatch

- Add `@callback` definitions in `Haul.Domains` for cert operations
- Add public functions `add_cert/1`, `check_cert/1`, `remove_cert/1`
- Add private `cert_adapter/0`
- No tests needed yet — tested via worker tests

## Step 3: Sandbox Adapter

- Create `lib/haul/domains/sandbox.ex`
- Implement all callbacks with immediate success responses
- This is what tests will use

## Step 4: FlyApi Adapter

- Create `lib/haul/domains/fly_api.ex`
- Implement add_cert: POST /apps/{app}/certificates
- Implement check_cert: GET /apps/{app}/certificates/{hostname}
- Implement remove_cert: DELETE /apps/{app}/certificates/{hostname}
- Uses Req with Bearer token auth
- Reads config: `fly_api_token`, `fly_app_name`

## Step 5: Domain Email Notification

- Create `lib/haul/notifications/domain_email.ex`
- `cert_failed/2` — builds Swoosh email about provisioning failure

## Step 6: ProvisionCert Worker

- Create `lib/haul/workers/provision_cert.ex`
- queue: :certs, max_attempts: 3
- perform/1 dispatches on args["action"]
- "add": add_cert → poll check_cert (5s interval, 24 iterations = 2 min) → update company → broadcast
- "remove": remove_cert (best-effort)
- On final failure: send DomainEmail.cert_failed

## Step 7: Config Updates

- config.exs: add `certs: 3` queue, `cert_adapter: Haul.Domains.Sandbox`
- runtime.exs: FLY_API_TOKEN + FLY_APP_NAME → set cert_adapter to FlyApi

## Step 8: LiveView Integration

- domain_settings_live.ex: after DNS verify success → set :provisioning, enqueue add job
- After confirm_remove → enqueue remove job before clearing domain
- Subscribe to PubSub on mount
- Handle PubSub broadcast to refresh company state

## Step 9: Tests

- Create `test/haul/workers/provision_cert_test.exs`
- Test add flow: company domain_status becomes :active, domain_verified_at is set
- Test remove flow: returns :ok
- Test PubSub broadcast on status change
- Test notification sent on final failure (mock attempt count)

## Step 10: Verify

- `mix test` — all tests pass
- `mix format` — code formatted
- Manual review of integration points

## Testing Strategy

- **Unit tests:** ProvisionCert worker with sandbox adapter
- **Integration:** Company status transitions verified via Ash queries
- **No browser tests:** This ticket is backend-only; T-017-03 covers browser QA
- **Sandbox adapter:** All tests use sandbox — no network calls
