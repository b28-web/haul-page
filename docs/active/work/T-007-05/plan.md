# T-007-05 Plan — Browser QA for Notifications

## Prerequisites

- Dev server running: `just dev`
- Playwright MCP available
- Database with default tenant set up

## Step 1: Navigate to Booking Form

1. `browser_navigate` to `http://localhost:4000/book`
2. `browser_snapshot` — verify form renders
3. **Pass criteria:** "Book a Pickup" heading visible, all form fields present

## Step 2: Fill and Submit Booking with Email

1. Fill form fields via `browser_fill_form` or sequential `browser_click` + `browser_type`:
   - Your Name: "QA Test Customer"
   - Phone Number: "555-0199"
   - Email: "qa-test@example.com"
   - Pickup Address: "456 QA Test Ave"
   - What do you need picked up?: "Notification QA test — old furniture"
2. `browser_click` on "Submit Booking Request" button
3. `browser_snapshot` — capture confirmation screen
4. **Pass criteria:** "Thank You!" heading displayed, no error messages

## Step 3: Wait for Oban Workers

1. Brief pause (2-3 seconds) to allow async Oban workers to process
2. Workers are in the `:notifications` queue with up to 10 concurrent

## Step 4: Check Swoosh Dev Mailbox

1. `browser_navigate` to `http://localhost:4000/dev/mailbox`
2. `browser_snapshot` — capture mailbox state
3. **Verify:**
   - Operator alert email present (to: hello@junkandhandy.com, subject containing "QA Test Customer")
   - Customer confirmation email present (to: qa-test@example.com)
4. Click on operator alert email to view contents
5. `browser_snapshot` — capture email detail
6. **Verify email body contains:** customer name, phone, address, description
7. Navigate back, click on customer confirmation email
8. `browser_snapshot` — capture customer email detail
9. **Pass criteria:** Both emails present with correct recipients and content

## Step 5: Check Server Logs

1. Run `just dev-log 50` or equivalent to get recent server logs
2. **Verify:**
   - SMS sandbox log line present (e.g., `[SMS Sandbox] Sending to...`)
   - No Oban worker crash/failure logs
   - No 500 errors during the session
3. **Pass criteria:** SMS logged, no worker failures

## Step 6: Document Results

1. Record all findings in `progress.md`
2. Note pass/fail for each step
3. Include any screenshots or observations

## Bug Handling

- **Form doesn't load:** Check dev server status, restart if needed
- **Submission fails:** Check Job action and tenant setup
- **No emails in mailbox:** Check Oban worker logs, verify workers ran
- **Missing customer email:** Verify `customer_email` was filled before submit
- Trivial fixes applied inline; complex issues logged for separate tickets
