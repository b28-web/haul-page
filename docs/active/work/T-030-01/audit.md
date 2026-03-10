# Error Handling Audit — `lib/`

## Summary

| # | File | Line | Pattern | Classification |
|---|------|------|---------|---------------|
| 1 | `billing_webhook_controller.ex` | 154 | try/rescue around email delivery | **Keep** |
| 2 | `billing_webhook_controller.ex` | 230 | rescue ArgumentError (plan atom) | **Narrow** |
| 3 | `ai/cost_tracker.ex` | 53 | try/rescue around Ash.create | **Narrow** |
| 4 | `domains.ex` | 57 | rescue _ (DNS lookup) | **Keep** |
| 5 | `ai/chat/anthropic.ex` | 33 | try/rescue in Task (AI stream) | **Keep** |
| 6 | `ai/prompt.ex` | 39 | rescue ArgumentError (app_dir) | **Keep** |
| 7 | `workers/provision_cert.ex` | 114 | rescue around email delivery | **Keep** |
| 8 | `onboarding.ex` | 149 | try/rescue wrapping seed!/1 | **Narrow** |
| 9 | `workers/send_booking_email.ex` | 19 | `:ok` when Ash.get fails | **Fix return** |
| 10 | `workers/send_booking_sms.ex` | 17 | `:ok` when Ash.get fails | **Fix return** |
| 11 | `workers/provision_cert.ex` | 47 | `:ok` on cert removal failure | **Fix return** |
| 12 | `places/google.ex` | 14 | `{:ok, []}` on API failure | **Keep** |
| 13 | `plugs/require_auth.ex` | 25 | `with` catch-all else → redirect | **Keep** |
| 14 | `workers/cleanup_conversations.ex` | 12 | always `:ok`, errors logged | **Fix return** |

**Totals:** 7 Keep, 3 Narrow, 4 Fix return, 0 Remove.

---

## Keep (7 sites)

### 1. Billing webhook email rescue (`billing_webhook_controller.ex:154`)
Stripe webhook handlers must return 200 quickly. Email is a secondary side-effect. If Mailer.deliver raises, we log and continue. Webhook response is not affected. **Correct boundary code.**

### 4. DNS lookup rescue (`domains.ex:57`)
`:inet_res.lookup/4` can raise for network errors, bad input, timeouts. These are external system failures. Mapping all exceptions to `{:error, :dns_error}` is appropriate. Caller (`verify_dns`) already returns tagged error tuples. **Correct boundary code.**

### 5. AI streaming Task rescue (`ai/chat/anthropic.ex:33`)
Task is started with `Task.start/1` (fire-and-forget, not linked). If it crashes without rescue, the error vanishes — LiveView process never learns the stream failed. The rescue converts exceptions to `{:ai_error, message}` sent to the LiveView PID. **Required for error visibility.**

### 6. Prompt dir fallback (`ai/prompt.ex:39`)
`Application.app_dir/2` raises `ArgumentError` when the app isn't a release (dev/test). Fallback to `File.cwd!/0` based path. Rescue is already narrow (catches only `ArgumentError`). **Correct dev/test accommodation.**

### 7. Cert failure notification rescue (`workers/provision_cert.ex:114`)
Same pattern as #1. After cert provisioning exhausts retries, we attempt to email the operator. If that email fails, we log but don't re-raise — the cert failure is already handled. **Correct best-effort notification.**

### 12. Google Places `{:ok, []}` (`places/google.ex:14`)
Autocomplete is a progressive enhancement. When the API is unavailable (no key, HTTP error, non-200), returning empty suggestions lets the user type their address manually. Returning `{:error, ...}` would require LiveView error handling with no UX benefit. **Correct graceful degradation.**

### 13. Auth plug catch-all else (`plugs/require_auth.ex:25`)
All `with` failure modes (missing session, bad JWT, user not found, wrong role) result in the same action: redirect to login. A catch-all `else` is idiomatic here — enumerating each failure mode adds verbosity without changing behavior. **Correct auth pattern.**

---

## Narrow (3 sites)

### 2. Plan resolution rescue (`billing_webhook_controller.ex:230`)

**Current:** The entire `resolve_plan_from_session/1` function body is wrapped in an implicit `rescue ArgumentError -> :pro`. If any code besides `String.to_existing_atom/1` raises `ArgumentError`, the bug is silently masked.

**Recommendation:** Isolate the atom conversion:
```elixir
defp safe_plan_atom(plan) when is_binary(plan) and plan != "" do
  String.to_existing_atom(plan)
rescue
  ArgumentError -> :pro
end
```

**Caller impact:** None — same return value on the happy path. Bug masking eliminated on error paths.
**Tests asserting current behavior:** No tests for invalid plan metadata.

### 3. Cost tracker rescue (`ai/cost_tracker.ex:53`)

**Current:** `rescue e ->` catches all exceptions after Ash.create. The inner `case` already handles `{:ok, entry}` and `{:error, reason}`. The rescue only fires on unexpected crashes (e.g., Ecto connection pool exhaustion, encoding errors).

**Recommendation:** Narrow to `Ecto.StaleEntryError` and `DBConnection.ConnectionError`, or remove the rescue entirely and rely on the `case` clause. The non-fatal design is preserved by the caller (`record_call/1`) which returns `{:error, ...}` — callers already handle that.

**Caller impact:** Callers already pattern-match on `{:ok, _}` or `{:error, _}`. Narrowing changes nothing for them.
**Tests asserting current behavior:** No tests for cost_tracker error paths.

### 8. Onboarding seed_content rescue (`onboarding.ex:149`)

**Current:** `try/rescue` wraps `Seeder.seed!/1` to convert exceptions to `{:error, :content_seed, message}`.

**Recommendation:** If `Seeder` can provide a non-bang `seed/2` returning `{:ok, summary} | {:error, reason}`, use that instead. If not, narrow the rescue to the specific exceptions `seed!` raises (likely `Ash.Error.Invalid`, `File.Error`). The current broad rescue hides unexpected failures in the seeder.

**Caller impact:** The `with` chain in `run/1` and `signup/1` already matches `{:error, :content_seed, _}`. No change needed.
**Tests asserting current behavior:** Onboarding tests exist but don't specifically test seed failure paths.

---

## Fix Return (4 sites)

### 9. SendBookingEmail `:ok` on missing job (`workers/send_booking_email.ex:19`)

**Current:** `{:error, _} -> :ok` — any Ash.get failure returns `:ok`.

**Problem:** Two failure modes are conflated:
- Job record deleted (expected — booking cancelled) → `:ok` is correct
- DB connection error (transient) → should return `{:error, reason}` for Oban retry

**Recommendation:**
```elixir
case Ash.get(Job, job_id, tenant: tenant) do
  {:ok, job} -> # ... send emails
  {:error, %Ash.Error.Query.NotFound{}} -> :ok
  {:error, reason} -> {:error, reason}
end
```

**Test impact:** Test `test/haul/workers/send_booking_email_test.exs` asserts `:ok` on missing job. Test must be updated to use specific not-found setup and add a separate test for DB error propagation.

### 10. SendBookingSms `:ok` on missing job (`workers/send_booking_sms.ex:17`)

**Same analysis as #9.** Identical pattern, identical fix.

**Test impact:** Same — `send_booking_sms_test.exs` asserts `:ok` on missing job.

### 11. ProvisionCert remove action `:ok` on error (`workers/provision_cert.ex:47`)

**Current:** Cert removal failure returns `:ok`, preventing Oban retries.

**Problem:** If `Domains.remove_cert/1` fails transiently (network timeout, API rate limit), the cert remains but the job doesn't retry. Dangling certs waste resources and may cause routing conflicts.

**Recommendation:**
```elixir
{:error, reason} ->
  Logger.warning("Cert removal failed for #{domain}: #{inspect(reason)}")
  {:error, reason}  # Let Oban retry
```

**Test impact:** `provision_cert_test.exs` does not test the remove-error path. New test needed.

### 14. CleanupConversations always `:ok` (`workers/cleanup_conversations.ex:12`)

**Current:** `perform/1` calls two helpers that log errors but don't propagate them. Job always reports success.

**Problem:** If `Ash.read` fails (DB issue), zero conversations are cleaned up but the job says it succeeded. Over time, stale conversations accumulate.

**Recommendation:** Have helpers return `{:ok, count}` or `{:error, reason}`. Propagate first error from `perform/1`:
```elixir
def perform(%Oban.Job{}) do
  cutoff = DateTime.add(DateTime.utc_now(), -@stale_days, :day)
  with :ok <- mark_stale_as_abandoned(cutoff),
       :ok <- delete_old_abandoned(cutoff) do
    :ok
  end
end
```

**Test impact:** `cleanup_conversations_test.exs` tests happy paths only. No error path tests to update, but new ones should be added.

---

## Oban Worker Return Value Reference

| Return | Oban behavior |
|--------|--------------|
| `:ok` | Job marked complete |
| `{:ok, value}` | Job marked complete |
| `{:error, reason}` | Job marked failed; retried up to `max_attempts` |
| `{:cancel, reason}` | Job cancelled; no more retries |
| `{:snooze, seconds}` | Job rescheduled after delay |

Workers returning `:ok` on transient failures prevent Oban's retry mechanism from working.

---

## Recommendations for Downstream Tickets

### T-030-02 (fix-defensive-rescues) — 3 sites
1. Narrow `billing_webhook_controller.ex` plan rescue to isolated helper
2. Narrow `cost_tracker.ex` rescue to specific DB exceptions or remove entirely
3. Narrow `onboarding.ex` seed_content rescue to specific seeder exceptions

### T-030-03 (fix-worker-errors) — 4 sites
1. Fix `send_booking_email.ex` to distinguish not-found from DB errors
2. Fix `send_booking_sms.ex` same pattern
3. Fix `provision_cert.ex` remove action to propagate errors
4. Fix `cleanup_conversations.ex` to propagate read failures
