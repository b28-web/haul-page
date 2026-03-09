# T-003-04 Research — Browser QA for Booking Form

## Scope

Automated browser QA for the booking form at `/book`. Verify rendering, validation, submission, confirmation, and mobile responsiveness using Playwright MCP.

## Relevant Files

| File | Role |
|------|------|
| `lib/haul_web/live/booking_live.ex` | BookingLive — form, validation, submission, photo upload, confirmation |
| `lib/haul/operations/job.ex` | Job Ash resource — state machine, `:create_from_online_booking` action |
| `lib/haul/storage.ex` | Photo upload storage backend (local or S3) |
| `lib/haul_web/router.ex` | Route: `live "/book", BookingLive` in browser scope |
| `lib/haul_web/components/core_components.ex` | `<.input>` component with error display |
| `test/haul_web/live/booking_live_test.exs` | Unit tests (12 tests) |
| `test/haul_web/live/booking_live_upload_test.exs` | Upload unit tests (8 tests) |

## BookingLive Architecture

- **Mount:** Loads operator config (phone, business_name, slug), provisions tenant schema, initializes AshPhoenix form for `Job :create_from_online_booking`, configures uploads (5 max, 10MB each, jpg/png/webp/heic).
- **Form fields:** customer_name (text, required), customer_phone (tel, required), customer_email (email, optional), address (text, required), item_description (textarea, required), photos (file upload, optional), preferred_dates (3x date inputs, optional).
- **Validation:** Real-time via `phx-change="validate"` → `AshPhoenix.Form.validate/2`. Errors rendered inline by `<.input>` component.
- **Submission:** `phx-submit="submit"` → merges date fields, uploads photos to storage, calls `AshPhoenix.Form.submit/2`. On success, sets `@submitted = true` showing confirmation. On error, re-renders form with errors.
- **Confirmation:** Shows "Thank You!" heading, contact info, "Submit Another Request" button (triggers `reset` event).
- **Photo upload:** LiveView file uploads with previews, progress bars, cancel buttons. Stored via `Haul.Storage` module.

## Job Resource

- Required attributes: customer_name, customer_phone, address, item_description
- Optional: customer_email, preferred_dates (date array), photo_urls (string array)
- Initial state: `:lead`
- Multi-tenant via `:context` strategy

## Error Display Pattern

The `<.input>` component extracts errors from AshPhoenix form fields and renders them as:
```html
<p class="mt-1.5 flex gap-2 items-center text-sm text-error">
  <icon exclamation-circle />
  Error message text
</p>
```

## Prior Browser QA Patterns

T-002-04 (landing page) and T-005-04 (scan page) established the pattern:
1. Navigate to page, take snapshot
2. Verify key elements present
3. Test interactions (if applicable)
4. Resize to mobile viewport (375×812), re-verify
5. Check server logs for errors

## Known Issues

- T-010-01 ticket mentions a `@max_photos` KeyError but current code does not reference `@max_photos` as an assign — it uses the module attribute directly. The template appears correct.
- Dev server must be running (`just dev`) for Playwright tests.

## Constraints

- This is a QA-only ticket — no code changes expected unless bugs are found.
- Playwright MCP tools: `browser_navigate`, `browser_snapshot`, `browser_fill_form`, `browser_click`, `browser_resize`, `browser_take_screenshot`.
- Form submission creates real database records in the tenant schema.
- Photo upload requires local storage directory to exist.

## Test Data

Per ticket test plan:
- Name: "Test Customer"
- Phone: "555-0100"
- Address: "123 Test St"
- Item description: "Old couch removal"
