# T-017-02 Design: Cert Provisioning

## Decision: Adapter Pattern for Fly API

### Option A: Direct Req calls in worker
Put HTTP calls directly in ProvisionCert worker. Simple, but hard to test and no dev/test story.

### Option B: Adapter pattern on Domains module (CHOSEN)
Add cert operation callbacks to `Haul.Domains` module with adapter dispatch. `Haul.Domains.FlyApi` for production, `Haul.Domains.Sandbox` for dev/test. Follows established pattern from Billing, Places, SMS modules.

**Why:** Testable without network calls. Consistent with codebase patterns. Clean separation.

### Option C: Separate CertProvisioner behaviour module
New top-level module just for cert ops. Overkill — Domains already exists and is the right home.

## Decision: Polling Strategy

### Option A: Recursive Oban job scheduling
Worker adds cert, then schedules itself with `scheduled_at: 10 seconds later` to check status. Each invocation checks and re-schedules until done or max retries.

### Option B: Single job with internal polling loop (CHOSEN)
Worker adds cert, then polls in a loop (sleep 5s, check, repeat up to ~2 minutes). If not ready after 2 min, return `{:error, :timeout}` to trigger Oban retry with backoff.

**Why:** Simpler. Cert provisioning is fast (usually <60s). No proliferation of jobs. Oban's built-in retry with backoff handles the failure case. 3 attempts × 2 min polling = 6 min max active time, reasonable for a background queue.

### Option C: PubSub or webhook from Fly
Fly doesn't offer cert webhooks. Not viable.

## Decision: Worker Actions

Single `ProvisionCert` worker handles both add and remove via an `"action"` arg:
- `"add"` — add cert, poll, update company status
- `"remove"` — remove cert from Fly (best-effort, don't fail if already gone)

## Decision: domain_verified_at Field

Add `domain_verified_at` (utc_datetime) to Company. Set when cert is successfully provisioned and domain becomes active. This is when the domain is fully verified end-to-end (DNS + TLS), not just DNS check passed.

Migration: simple `alter table` adding the column.

## Decision: Failure Notification

After 3 failed attempts (Oban max_attempts), send email to operator. Use existing `Haul.Mailer` + Swoosh pattern. Create `Haul.Notifications.DomainEmail.cert_failed/2`.

However, Oban doesn't have a built-in "on all retries exhausted" hook in the worker itself. Options:
- Use `Oban.Plugins.Lifeline` or custom plugin — too heavy
- Check `attempt == max_attempts` in the worker and send email before returning error
- Use Oban telemetry — adds complexity

**Chosen:** Check `job.attempt >= 3` in the worker. If the final attempt also fails, send the notification email, then return `{:error, reason}`. The job goes to :discarded but the operator is notified.

## Decision: Config

- `config :haul, :cert_adapter` — defaults to `Haul.Domains.Sandbox`
- `FLY_API_TOKEN` env var → sets adapter to `Haul.Domains.FlyApi`
- `FLY_APP_NAME` env var → required when FLY_API_TOKEN is set
- Oban queue: `certs: 3` (low concurrency, cert ops are sequential per domain)

## Integration Points

### LiveView → Worker (enqueue)
In `domain_settings_live.ex`:
- After DNS verify succeeds: set domain_status to `:provisioning`, enqueue `ProvisionCert.new(%{"company_id" => id, "action" => "add"})`
- After domain removal confirmed: enqueue `ProvisionCert.new(%{"company_id" => id, "domain" => domain, "action" => "remove"})` before clearing domain

### Worker → Company (status updates)
- On cert ready: set `domain_status: :active`, `domain_verified_at: DateTime.utc_now()`
- On cert failure (final): leave `domain_status: :provisioning` (operator can retry via UI later)

### Worker → LiveView (real-time updates)
Use PubSub to broadcast domain status changes. LiveView subscribes on mount.
Topic: `"domain:#{company.id}"`, event: `"status_changed"`.

## Architecture Summary

```
User clicks "Verify DNS"
  → LiveView calls Domains.verify_dns/2
  → On success: update company domain_status=:provisioning
  → Enqueue ProvisionCert (action: "add")
  → LiveView shows "Setting up SSL..." state

ProvisionCert worker runs:
  → Calls Domains.add_cert(domain)
  → Polls Domains.check_cert(domain) every 5s for 2 min
  → On ready: update company domain_status=:active, domain_verified_at=now
  → Broadcast via PubSub
  → On timeout: return {:error, :timeout} → Oban retries
  → On 3rd failure: send DomainEmail.cert_failed, return {:error, reason}

User clicks "Remove Domain"
  → LiveView enqueues ProvisionCert (action: "remove", domain: old_domain)
  → LiveView clears company domain/domain_status
  → Worker calls Domains.remove_cert(domain) (best-effort)
```
