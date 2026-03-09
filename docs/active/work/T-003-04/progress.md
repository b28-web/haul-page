# T-003-04 Progress — Browser QA for Booking Form

## Prerequisites

- Dev server: restarted via `just dev-down && just dev` (needed fresh config load)
- Tenant provisioned: Created Company "Junk & Handy" (slug: junk-and-handy) to provision `tenant_junk-and-handy` schema with jobs table
- Playwright MCP: connected

## Step 1: Page Load — PASS

- Navigated to `http://localhost:4000/book`
- Page title: "Book a Pickup · Phoenix Framework"
- H1 heading: "Book a Pickup"
- Subtitle: "Fill out the form below and we'll get back to you to confirm."
- No errors on load

## Step 2: Field Inventory — PASS

All fields present and correctly labeled:
- ✅ customer_name — textbox "Your Name", placeholder "Jane Doe"
- ✅ customer_phone — textbox "Phone Number", placeholder "(555) 123-4567"
- ✅ customer_email — textbox "Email (optional)", placeholder "you@example.com"
- ✅ address — textbox "Pickup Address", placeholder "123 Main St, Anytown, USA"
- ✅ item_description — textbox "What do you need picked up?", placeholder "Old couch, two mattresses, broken dresser..."
- ✅ Photo upload — camera icon, "Tap to add photos" label
- ✅ Preferred dates — 3 date inputs
- ✅ Submit button — "Submit Booking Request"
- ✅ Phone CTA — "Or call us directly: (555) 123-4567"

## Step 3: Validation — PASS

### HTML5 native validation
- Clicking submit on empty form triggers browser-native `required` validation (focuses first empty required field). This is correct behavior.

### Ash server-side validation
- Used JavaScript `novalidate` + `requestSubmit()` to bypass native validation
- All 4 required field errors displayed:
  - "is required" on Your Name
  - "is required" on Phone Number
  - "is required" on Pickup Address
  - "is required" on item description
- Optional fields (email, photos, dates) correctly show NO errors
- No 500 errors

### LiveView change validation
- Typed and cleared "Your Name" field → "is required" error appeared in real-time via phx-change

## Step 4: Happy Path Submission — PASS

- Filled form: Name="Test Customer", Phone="555-0100", Address="123 Test St", Description="Old couch removal"
- Clicked "Submit Booking Request"
- Confirmation screen displayed:
  - ✅ "Thank You!" heading
  - ✅ "Your booking request has been received. We'll contact you shortly to confirm your pickup."
  - ✅ Phone link "(555) 123-4567" (tel: link)
  - ✅ "Submit Another Request" button
  - ✅ "Junk & Handy" business name
- No console errors, no 500s

### Issue encountered & resolved
- Initial submission failed with `Postgrex.Error: relation "tenant_default.jobs" does not exist`
- Root cause: no tenant schema existed in dev database
- Fix: Provisioned Company via `Ash.create(Company, :create_company, ...)` which triggered ProvisionTenant change → created `tenant_junk-and-handy` schema with all tables
- After restart, submission succeeded

## Step 5: Form Reset — PASS

- Clicked "Submit Another Request" on confirmation screen
- Form reappeared with all fields empty
- All labels and placeholders correct
- Ready for new submission

## Step 6: Mobile Viewport (375×812) — PASS

- Resized to 375×812 (iPhone X)
- Navigated to `/book` (fresh load)
- All fields render properly — single column layout
- No horizontal overflow
- Submit button full-width
- Date inputs stack vertically (1 column instead of 3)
- Phone CTA visible
- Screenshot saved: `docs/active/work/T-003-04/mobile-375x812.png`

## Step 7: Server Health — PASS

- Checked `.dev.log` — no errors, no 500s during test session
- All LiveView events processed normally

## Screenshots

- `desktop-1280x800.png` — Desktop full page
- `mobile-375x812.png` — Mobile full page (375×812)
