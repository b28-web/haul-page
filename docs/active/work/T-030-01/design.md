# T-030-01 Design: Audit Error Handling

## Approach

This is a research-only ticket. The deliverable is `audit.md` classifying every error handling site. No code changes.

## Classification Framework

Each site is classified using the ticket's four categories:

- **Remove** — Defensive rescue hiding bugs. Let it crash; supervisor handles restart.
- **Narrow** — Rescue is valid but catches too broadly. Should catch specific exceptions.
- **Keep** — Legitimate boundary code. External APIs, user input, expected failure modes.
- **Fix return** — Worker/function should propagate errors instead of swallowing them.

## Classification Decisions

### Keep (7 sites)

1. **billing_webhook email rescue** (site 1) — Webhook must return 200 to Stripe. Email is secondary notification. Keep.
2. **domains.ex DNS rescue** (site 4) — DNS is external; any exception maps to `{:error, :dns_error}`. Keep.
3. **anthropic.ex Task rescue** (site 5) — Unlinked Task has no caller to propagate to. Must send error message. Keep.
4. **prompt.ex dev fallback** (site 6) — `Application.app_dir/2` legitimately raises in dev/test. Narrow `ArgumentError` catch is already specific. Keep.
5. **provision_cert notification rescue** (site 7) — Same pattern as billing webhook email. Best-effort notification. Keep.
6. **require_auth catch-all** (site 13) — Auth plug. All failure modes → redirect to login. Correct behavior. Keep.
7. **google places `{:ok, []}`** (site 12) — External API. Graceful degradation is correct UX (empty suggestions, user types manually). Keep.

### Narrow (2 sites)

1. **billing_webhook plan rescue** (site 2) — Catches `ArgumentError` from `String.to_existing_atom/1`, which is already narrow. But the entire function body is wrapped. If any other code in the function raises `ArgumentError`, it silently defaults to `:pro`. Should narrow the rescue to just the `to_existing_atom` call.
2. **cost_tracker rescue** (site 3) — Catches all exceptions with `rescue e ->`. The `Ash.create` call returns `{:error, reason}` on normal failures (handled in the `case`). The rescue catches unexpected crashes. Should narrow to specific Ash/Ecto exceptions, or remove entirely since the `case` already handles errors.

### Fix Return (4 sites)

1. **send_booking_email `:ok` on missing job** (site 9) — If `Ash.get` fails, the job record may have been deleted (legitimate) or there's a DB error (bug). Should distinguish: not-found → `:ok`, other errors → `{:error, reason}`.
2. **send_booking_sms `:ok` on missing job** (site 10) — Same pattern as email worker.
3. **provision_cert remove `:ok` on error** (site 11) — Cert removal failure silently succeeds. Should return `{:error, reason}` to trigger Oban retry, since a dangling cert wastes resources.
4. **cleanup_conversations always-ok** (site 14) — DB query failures are logged but don't propagate. If `Ash.read` fails, no conversations are cleaned up but the job reports success. Should propagate read failures.

### Remove (1 site)

1. **onboarding seed_content rescue** (site 8) — Wraps `Seeder.seed!/1` in try/rescue to convert to error tuple. The better fix: use `Seeder.seed/1` (non-bang) if it exists, or change the caller's `with` chain to expect exceptions. However, if `seed!` is the only API, the try/rescue is a pragmatic adapter. **Reclassify as Narrow** — the rescue catches all exceptions when it should only catch the specific ones `seed!` raises.

**Revised: Remove → 0 sites, Narrow → 3 sites (including onboarding)**

## Rejected Alternatives

- **Classify all worker `:ok` returns as "keep"**: Rejected. While "fire and forget" is common for notification workers, silently succeeding when data can't be loaded (DB error vs. not-found) hides intermittent issues. The distinction matters for observability.
- **Classify cost_tracker as "remove"**: Rejected. Cost tracking being non-fatal is a deliberate design decision documented in the module. But the broad rescue should be narrowed.
- **Classify google places as "fix return"**: Rejected. The UI is designed for graceful degradation. Returning `{:error, ...}` would require error handling in the LiveView with no UX benefit — user still can't autocomplete.
