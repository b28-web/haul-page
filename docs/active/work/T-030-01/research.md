# T-030-01 Research: Audit Error Handling

## Scope

All error handling sites in `lib/` — `rescue`, `try/rescue`, `catch`, `with` catch-all else clauses, workers returning `:ok` on failure, and functions returning `{:ok, default}` on error.

## Error Handling Sites Found

### Rescue Blocks (8 sites)

#### 1. `lib/haul_web/controllers/billing_webhook_controller.ex:154-159`
**Pattern:** `try/rescue` around email delivery in payment_failed webhook handler.
```elixir
try do
  company |> BillingEmail.payment_failed() |> Mailer.deliver()
rescue
  e -> Logger.warning("...")
end
```
**Context:** Best-effort notification during Stripe webhook processing. Webhook must return 200 regardless. Email failure shouldn't block dunning state update.

#### 2. `lib/haul_web/controllers/billing_webhook_controller.ex:230-246`
**Pattern:** `rescue ArgumentError` on `String.to_existing_atom/1` in `resolve_plan_from_session/1`.
```elixir
defp resolve_plan_from_session(session) do
  # ... String.to_existing_atom(plan)
rescue
  ArgumentError -> :pro
end
```
**Context:** Stripe metadata may contain invalid plan strings. Falls back to `:pro` plan.

#### 3. `lib/haul/ai/cost_tracker.ex:53-73`
**Pattern:** `try/rescue` around Ash.create for cost entry persistence.
```elixir
try do
  # Ash.Changeset.for_create + Ash.create
rescue
  e -> {:error, :recording_failed}
end
```
**Context:** Cost tracking is explicitly non-fatal by design. Caller's AI operation must not fail due to accounting.

#### 4. `lib/haul/domains.ex:57-76`
**Pattern:** `rescue _` around `:inet_res.lookup` DNS call.
```elixir
def verify_dns(domain, base_domain) do
  # ... :inet_res.lookup(...)
rescue
  _ -> {:error, :dns_error}
end
```
**Context:** DNS lookups can fail for numerous reasons (network, timeouts, invalid input). External boundary code.

#### 5. `lib/haul/ai/chat/anthropic.ex:33-38`
**Pattern:** `try/rescue` inside spawned Task for AI streaming.
```elixir
Task.start(fn ->
  try do
    stream_response(body, pid)
  rescue
    e -> send(pid, {:ai_error, Exception.message(e)})
  end
end)
```
**Context:** Task runs outside supervision tree. Error must be communicated to LiveView process via message. Without rescue, error is silently lost in the Task.

#### 6. `lib/haul/ai/prompt.ex:39-44`
**Pattern:** `rescue ArgumentError` on `Application.app_dir/2`.
```elixir
defp prompts_dir do
  Application.app_dir(:haul, "priv/prompts")
rescue
  ArgumentError -> Path.join(File.cwd!(), "priv/prompts")
end
```
**Context:** `app_dir` raises when app isn't started as a release. Legitimate dev/test fallback.

#### 7. `lib/haul/workers/provision_cert.ex:114-120`
**Pattern:** `rescue` around email delivery in failure notification helper.
```elixir
defp send_failure_notification(company, domain) do
  email = DomainEmail.cert_failed(company, domain)
  Haul.Mailer.deliver(email)
rescue
  error -> Logger.warning("...")
end
```
**Context:** Best-effort notification when cert provisioning fails after max retries. Similar to billing webhook email pattern.

#### 8. `lib/haul/onboarding.ex:149-155`
**Pattern:** `try/rescue` wrapping `Seeder.seed!/1` (bang function).
```elixir
defp seed_content(tenant) do
  try do
    summary = Seeder.seed!(tenant, defaults_content_root())
    {:ok, summary}
  rescue
    e -> {:error, :content_seed, Exception.message(e)}
  end
end
```
**Context:** Converts bang-function exceptions into error tuples for `with` chain in `run/1` and `signup/1`. The Seeder raises on invalid content.

### Workers Returning `:ok` on Failure (3 sites)

#### 9. `lib/haul/workers/send_booking_email.ex:19-21`
```elixir
{:error, _} -> :ok  # Job not found — returns :ok
```
**Context:** If the Job record is gone by the time the worker runs, no email can be sent. Also, `Mailer.deliver()` return value is ignored.

#### 10. `lib/haul/workers/send_booking_sms.ex:17-19`
```elixir
{:error, _} -> :ok  # Job not found — returns :ok
```
**Context:** Same pattern as email worker. `SMS.send_sms()` return value is also ignored.

#### 11. `lib/haul/workers/provision_cert.ex:47-50` (remove action)
```elixir
{:error, reason} ->
  Logger.warning("Cert removal failed for #{domain}: #{inspect(reason)}")
  :ok  # Returns :ok even on cert removal failure
```
**Context:** Cert removal failure is logged but doesn't trigger Oban retry.

### Functions Returning `{:ok, default}` on Error (1 site, 3 paths)

#### 12. `lib/haul/places/google.ex:14-38`
```elixir
# Three paths all return {:ok, []} on failure:
nil -> {:ok, []}           # No API key configured
{:ok, %{status: non-200}} -> {:ok, []}  # API error response
{:error, reason} -> {:ok, []}           # HTTP request failure
```
**Context:** Autocomplete is degraded-gracefully by design. UI shows empty suggestions. User can still type address manually.

### With Catch-All Else (1 site)

#### 13. `lib/haul_web/plugs/require_auth.ex:25-29`
```elixir
else
  _ -> conn |> redirect(to: "/app/login") |> halt()
end
```
**Context:** Auth plug. Any failure in the `with` chain (missing session, bad JWT, unknown user, wrong role) redirects to login. Catch-all is appropriate — all failure modes have the same response.

### Worker Always-`:ok` Pattern (1 site)

#### 14. `lib/haul/workers/cleanup_conversations.ex:12-20`
```elixir
def perform(%Oban.Job{}) do
  mark_stale_as_abandoned(cutoff)  # errors logged, not propagated
  delete_old_abandoned(cutoff)     # errors logged, not propagated
  :ok
end
```
**Context:** Maintenance worker. Helper functions log errors but don't propagate them. Always returns `:ok`.

## Test Coverage of Error Paths

| Site | Tests exist? | Tests error path? |
|------|-------------|-------------------|
| billing_webhook email rescue | Yes (controller test) | No |
| billing_webhook plan rescue | Yes (controller test) | No |
| cost_tracker rescue | No | No |
| domains.ex DNS rescue | Yes (domains_test) | Unclear |
| anthropic.ex Task rescue | No | No |
| prompt.ex dev fallback | No | No |
| provision_cert notification rescue | Yes | No |
| onboarding seed_content rescue | Yes | Partial |
| send_booking_email `:ok` on missing job | Yes | Yes — asserts `:ok` |
| send_booking_sms `:ok` on missing job | Yes | Yes — asserts `:ok` |
| provision_cert remove `:ok` on error | Yes | No |
| google places `{:ok, []}` | Yes (places tests) | Likely |
| require_auth catch-all | Yes (plug test) | Likely |
| cleanup_conversations always-ok | Yes | No |
