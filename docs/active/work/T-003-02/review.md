# Review — T-003-02 Booking LiveView

## Summary

Built the `/book` page as a LiveView form that creates Jobs in `:lead` state via the `:create_from_online_booking` Ash action. The form uses AshPhoenix.Form for validation and submission, styled consistently with the existing dark-theme landing page.

## Files created

| File | Purpose |
|------|---------|
| `lib/haul_web/live/booking_live.ex` | BookingLive LiveView — form + confirmation states |
| `test/haul_web/live/booking_live_test.exs` | 13 tests covering rendering, submission, validation |

## Files modified

| File | Change |
|------|--------|
| `lib/haul_web/router.ex` | Added `live "/book", BookingLive` route |
| `config/config.exs` | Added `slug: "junk-and-handy"` to operator config |
| `priv/repo/seeds.exs` | Added Company creation seeding for default operator tenant |

## Acceptance criteria status

| Criterion | Status |
|-----------|--------|
| `HaulWeb.BookingLive` serves at `GET /book` | ✅ |
| Form fields: name, phone, email, address, item description, preferred dates | ✅ |
| Real-time validation (phx-change) with clear error messages | ✅ |
| On submit: calls `:create_from_online_booking` on Job resource | ✅ |
| Success: shows confirmation with "we'll contact you" copy | ✅ |
| Mobile-optimized: large inputs, proper keyboard types | ✅ (input-lg, type=tel/email/date) |
| Styled consistently with landing page (dark theme, same font) | ✅ |

## Test coverage

- **13 tests, 0 failures**
- Rendering: form elements present, field labels, input types (tel, email, date), operator phone
- Submission: successful job creation shows confirmation, operator phone in confirmation, form reset
- Validation: empty form shows "is required" errors, change events don't crash
- Full suite: 86 tests, 0 failures (no regressions)

### Coverage gaps

- No test for preferred dates being included in the created Job (would require querying the DB after submit)
- No test for the `notes` field (not in the form — could be added as future enhancement)
- No visual/browser test (deferred to T-003-04 browser QA)

## Architecture decisions

1. **AshPhoenix.Form integration**: Used `AshPhoenix.Form.for_create/3` with `tenant:` option. Keeps `ash_form` (AshPhoenix.Form struct) and `form` (Phoenix.HTML.Form) as separate assigns. The ash_form is the source of truth; the Phoenix form is derived via `to_form/2`.

2. **Tenant resolution**: Added `slug` to operator config. Tenant derived as `"tenant_#{slug}"` via `ProvisionTenant.tenant_schema/1`. No DB query on page load. Seeds ensure the Company and tenant schema exist.

3. **Preferred dates UX**: Three fixed date inputs with `min` set to today. Non-empty dates merged into `preferred_dates` array param before Ash submission.

4. **Two-state render**: `@submitted` boolean toggles between form and confirmation panel. Reset event rebuilds a fresh form.

## Open concerns

1. **Tenant must exist before form works**: If seeds haven't been run (no Company in DB), the form will render but submission will fail because the tenant schema doesn't exist. The seeds must be run as part of deployment (`mix run priv/repo/seeds.exs`).

2. **No `notes` field in form**: The Job resource accepts a `notes` attribute but the acceptance criteria didn't list it. Could be added later.

3. **No photo upload**: Spec mentions "load photos" but this is deferred (likely T-003-03 or later).

4. **No rate limiting**: The public form has no rate limiting or CAPTCHA. Could be abused. Consider adding Plug rate limiting or a honeypot field.

5. **Slug in config must match seeded Company**: If the operator slug in config doesn't match any Company, submissions fail. The seeds script handles this by using the config slug when creating the Company.

## Cross-ticket notes

- **T-003-03** (if it exists): Photo upload can be added to this form as a LiveView file upload component
- **T-003-04** (browser QA): Should test the booking form flow end-to-end with Playwright
- **T-007-01+** (notifications): After submit, the operator should get notified. Currently no notification is sent — just a Job record is created.
