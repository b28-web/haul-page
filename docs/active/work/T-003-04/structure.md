# T-003-04 Structure — Browser QA for Booking Form

## Overview

No code changes expected — this is a QA-only ticket. Structure defines the test execution plan and artifact layout.

## Artifacts Produced

```
docs/active/work/T-003-04/
├── research.md          # Codebase mapping (this phase)
├── design.md            # Approach decision
├── structure.md         # This file
├── plan.md              # Step-by-step test plan
├── progress.md          # Execution log with results
└── review.md            # Final assessment
```

## Test Execution Structure

### Step 1: Page Load
- Tool: `browser_navigate` → `http://localhost:4000/book`
- Tool: `browser_snapshot` → verify DOM structure
- Verify: h1 "Book a Pickup", form element, all input fields

### Step 2: Field Inventory
From snapshot, confirm presence of:
- `customer_name` input (text, required)
- `customer_phone` input (tel, required)
- `customer_email` input (email)
- `address` input (text, required)
- `item_description` textarea (required)
- Photo upload area (camera icon, "Tap to add photos")
- 3x date inputs for preferred dates
- Submit button "Submit Booking Request"

### Step 3: Validation Test
- Tool: `browser_click` on submit button (empty form)
- Tool: `browser_snapshot` → verify error messages
- Expected errors on: customer_name, customer_phone, address, item_description

### Step 4: Happy Path Submission
- Tool: `browser_fill_form` with test data
- Tool: `browser_click` on submit
- Tool: `browser_snapshot` → verify confirmation screen
- Expected: "Thank You!" heading, phone link, "Submit Another Request" button

### Step 5: Form Reset
- Tool: `browser_click` on "Submit Another Request"
- Tool: `browser_snapshot` → verify form is back

### Step 6: Mobile Viewport
- Tool: `browser_resize` → 375×812
- Tool: `browser_navigate` → `/book` (fresh load)
- Tool: `browser_snapshot` → verify no overflow, fields usable

## Code Changes

None expected unless bugs are discovered during testing. If a bug blocks QA completion, it will be fixed inline and documented.

## Dependencies

- Dev server running on localhost:4000 (`just dev`)
- Database with tenant schema provisioned (handled by BookingLive mount)
- Playwright MCP server connected
