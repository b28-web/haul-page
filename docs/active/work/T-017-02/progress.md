# T-017-02 Progress: Cert Provisioning

## Completed Steps

### Step 1: Migration + Company Attribute
- Created migration `20260309080000_add_domain_verified_at_to_companies.exs`
- Added `domain_verified_at` attribute to Company resource
- Added to `update_company` accept list
- Migration ran successfully

### Step 2: Domains Module — Adapter Behaviour + Dispatch
- Defined `Haul.Domains.CertAdapter` behaviour with add_cert/1, check_cert/1, remove_cert/1
- Added public dispatch functions to `Haul.Domains`
- Private `cert_adapter/0` reads from config

### Step 3: Sandbox Adapter
- Created `lib/haul/domains/sandbox.ex` with immediate success responses

### Step 4: FlyApi Adapter
- Created `lib/haul/domains/fly_api.ex` with Req HTTP calls
- POST/GET/DELETE for certificates via Fly Machines API
- Bearer token auth, app name from config

### Step 5: Domain Email Notification
- Created `lib/haul/notifications/domain_email.ex`
- `cert_failed/2` builds failure notification email

### Step 6: ProvisionCert Worker
- Created `lib/haul/workers/provision_cert.ex`
- Handles "add" and "remove" actions
- Polls cert status every 5s for up to 2 minutes
- Updates company to :active with domain_verified_at on success
- Broadcasts PubSub on status change
- Sends notification email on final failure (attempt >= max_attempts)

### Step 7: Config Updates
- Added `certs: 3` Oban queue
- Added `cert_adapter: Haul.Domains.Sandbox` default
- Added FLY_API_TOKEN + FLY_APP_NAME runtime config

### Step 8: LiveView Integration
- DNS verify success → sets :provisioning, enqueues ProvisionCert add job
- Domain removal → enqueues ProvisionCert remove job, clears domain_verified_at
- PubSub subscription on mount for real-time status updates
- handle_info for domain_status_changed broadcasts

### Step 9: Tests
- 6 tests in provision_cert_test.exs, all passing
- Tests: add flow, no domain, non-existent company, PubSub broadcast, remove flow, unknown args

### Step 10: Verify
- `mix test` — 488 tests, 0 failures
- `mix format` — all code formatted
- No deviations from plan
