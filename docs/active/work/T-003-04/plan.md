# T-003-04 Plan — Browser QA for Booking Form

## Prerequisites

- Dev server running: `just dev`
- Playwright MCP available

## Step 1: Navigate and Verify Page Load

1. `browser_navigate` to `http://localhost:4000/book`
2. `browser_snapshot` — capture initial state
3. **Verify:** Page title "Book a Pickup", subtitle text, form renders
4. **Pass criteria:** No error page, form visible with all fields

## Step 2: Verify Form Fields Present

From the snapshot, confirm all fields:
- [x] customer_name — text input, label "Your Name", placeholder "Jane Doe"
- [x] customer_phone — tel input, label "Phone Number"
- [x] customer_email — email input, label "Email (optional)"
- [x] address — text input, label "Pickup Address"
- [x] item_description — textarea, label "What do you need picked up?"
- [x] Photo upload — camera icon area, "Tap to add photos"
- [x] Preferred dates — 3 date inputs
- [x] Submit button — "Submit Booking Request"
- **Pass criteria:** All fields present and labeled correctly

## Step 3: Validation — Submit Empty Form

1. `browser_click` on "Submit Booking Request" button
2. `browser_snapshot` — capture validation state
3. **Verify:** Error messages appear for required fields (name, phone, address, description)
4. **Pass criteria:** At least 4 validation errors visible, no server 500

## Step 4: Fill and Submit Valid Form

1. `browser_fill_form` or `browser_type` with:
   - Name: "Test Customer"
   - Phone: "555-0100"
   - Address: "123 Test St"
   - Item description: "Old couch removal"
2. `browser_click` on submit button
3. `browser_snapshot` — capture confirmation state
4. **Verify:** "Thank You!" heading, contact info, "Submit Another Request" button
5. **Pass criteria:** Confirmation screen displayed, no errors

## Step 5: Test Form Reset

1. `browser_click` on "Submit Another Request"
2. `browser_snapshot` — capture reset state
3. **Verify:** Form is back with empty fields
4. **Pass criteria:** Form displayed, fields empty

## Step 6: Mobile Viewport Test

1. `browser_resize` to 375×812
2. `browser_navigate` to `http://localhost:4000/book` (fresh load)
3. `browser_snapshot` — capture mobile state
4. **Verify:** Form fields visible, no horizontal overflow, inputs usable
5. **Pass criteria:** All fields accessible, layout adapts to narrow viewport

## Step 7: Final Server Health Check

1. Check dev server logs for any 500 errors during the test session
2. **Pass criteria:** No 500 errors logged

## Bug Handling

- If page doesn't load → check dev server, fix and retry
- If validation doesn't show → investigate form component, document finding
- If submission fails → check Job resource/action, document error
- Trivial fixes applied inline; complex issues logged for separate tickets
