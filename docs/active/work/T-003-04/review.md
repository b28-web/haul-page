# T-003-04 Review — Browser QA for Booking Form

## Summary

All acceptance criteria met. The booking form at `/book` renders correctly, validates required fields, submits successfully creating a Job in `:lead` state, shows a confirmation screen, and resets cleanly. Mobile layout (375×812) is responsive with no overflow.

## Acceptance Criteria Results

| Criteria | Result |
|----------|--------|
| Full booking flow completes without error | ✅ PASS |
| Validation errors display for empty/invalid submissions | ✅ PASS |
| Confirmation shown after successful submit | ✅ PASS |
| No 500 errors in server logs | ✅ PASS |

## Test Results Detail

### Desktop (1280×800)
- Page loads with all form fields, labels, and placeholders
- HTML5 native validation prevents empty submission (correct behavior)
- Server-side Ash validation shows "is required" errors for all 4 required fields
- Real-time phx-change validation works (errors appear on field blur)
- Submission with valid data → "Thank You!" confirmation screen
- "Submit Another Request" → form resets to empty state

### Mobile (375×812)
- All fields render in single-column layout
- Preferred dates stack vertically (3 rows instead of 1 row of 3)
- No horizontal overflow or cut-off elements
- Submit button spans full width
- Phone CTA visible at bottom

## Files Changed

None. This is a QA-only ticket — no code changes were made.

## Infrastructure Setup Required

During testing, the `tenant_junk-and-handy` schema did not exist in the dev database. This was provisioned by creating a Company record:

```elixir
Company
|> Ash.Changeset.for_create(:create_company, %{name: "Junk & Handy", slug: "junk-and-handy"})
|> Ash.create()
```

This triggered `ProvisionTenant` which created the schema and ran tenant migrations. This is normal for a fresh dev database — the tenant must be seeded before the booking form can submit.

## Open Concerns

1. **Dev database seeding:** Fresh dev environments have no tenant schema. The booking form renders fine but submission fails silently (form stays on page, warning in browser console). Consider adding tenant provisioning to `mix setup` or a seed script so `/book` works out-of-the-box for new developers. This is not a bug — it's a DX improvement.

2. **Silent submission failure UX:** When the tenant schema doesn't exist, the form submission fails with an `AshPhoenix.FormData.Error` protocol not implemented for `Ash.Error.Unknown.UnknownError`. The user sees the form remain on screen with no error message. A user-facing error flash would improve the experience. Low priority since this only affects misconfigured environments.

3. **Photo upload not tested in browser QA:** File upload via Playwright MCP is possible but was not tested because T-003-03 (photo-upload) handles that scope. The upload UI elements (camera icon, "Tap to add photos" label) are present and correctly rendered.

## Test Coverage

- **Browser QA (this ticket):** 7 test steps covering page load, field inventory, validation, happy path, reset, mobile, and server health
- **Existing unit tests:** 12 tests in `booking_live_test.exs` + 8 tests in `booking_live_upload_test.exs` = 20 tests
- **Coverage gap:** No automated browser test script — this was a manual Playwright MCP session. Future tickets could add a Playwright spec file for CI.

## Screenshots

- `docs/active/work/T-003-04/desktop-1280x800.png`
- `docs/active/work/T-003-04/mobile-375x812.png`
