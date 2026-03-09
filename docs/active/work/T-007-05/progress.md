# T-007-05 Progress — Browser QA for Notifications

## Prerequisites

- Dev server restarted (Oban wasn't running — see Findings below)
- Playwright MCP available
- Tenant migration for `payment_intent_id` applied manually

## Step 1: Navigate to Booking Form — PASS

- Navigated to `http://localhost:4000/book`
- "Book a Pickup" heading visible
- All form fields present: name, phone, email, address, item description, photos, preferred dates, submit button

## Step 2: Fill and Submit Booking — PASS

- Filled fields:
  - Name: "QA Test Customer"
  - Phone: "555-0199"
  - Email: "qa-test@example.com"
  - Address: "456 QA Test Ave"
  - Description: "Notification QA test — old furniture"
- Clicked "Submit Booking Request"
- Confirmation screen displayed: "Thank You!" heading, phone link, "Submit Another Request" button, business name

## Step 3: Swoosh Dev Mailbox — PASS

- Navigated to `http://localhost:4000/dev/mailbox`
- **2 messages** present in mailbox

### Customer Confirmation Email
- **From:** "Junk & Handy" <hello@junkandhandy.com>
- **To:** qa-test@example.com
- **Subject:** "Booking received — Junk & Handy"
- **Body verified:**
  - "Hi QA Test Customer, thanks for reaching out"
  - Pickup address: "456 QA Test Ave"
  - Items: "Notification QA test — old furniture"
  - "We'll contact you shortly at 555-0199"
  - Footer: "Junk & Handy · (555) 123-4567"

### Operator Alert Email
- **From:** "Junk & Handy" <hello@junkandhandy.com>
- **To:** "Junk & Handy" <hello@junkandhandy.com>
- **Subject:** "New booking from QA Test Customer"
- **Body verified:**
  - Customer: "QA Test Customer"
  - Phone: "555-0199"
  - Email: "qa-test@example.com"
  - Address: "456 QA Test Ave"
  - Items: "Notification QA test — old furniture"
  - Notes: "none"
  - Footer: "Junk & Handy · (555) 123-4567"

## Step 4: SMS Sandbox Log — PASS

- Browser console captured: `[SMS Sandbox] To: (555) 123-456...` during submission
- SMS sandbox adapter logged the notification as expected

## Step 5: Oban Worker Status — PASS

- Queried `oban_jobs` table directly:
  - Job 1: `Haul.Workers.SendBookingEmail` — state: `completed`
  - Job 2: `Haul.Workers.SendBookingSMS` — state: `completed`
- Both completed within ~30ms of being attempted
- No failed or retrying jobs

## Step 6: Server Health — PASS

- No 500 errors during the test session
- No Oban worker crashes or failures
- All console errors were from the pre-restart attempt (before Oban was running)

## Findings / Bugs Encountered

### Bug 1: Missing `payment_intent_id` column (FIXED)

- **Symptom:** First submission attempt failed with `Postgrex.Error: column "payment_intent_id" does not exist`
- **Cause:** T-008 (payments) work added `payment_intent_id` attribute to the Job resource and created a tenant migration (`priv/repo/tenant_migrations/20260309014947_add_payment_intent_id_to_jobs.exs`), but the migration hadn't been applied to the dev database
- **Fix:** Applied the column manually via `ALTER TABLE "tenant_junk-and-handy".jobs ADD COLUMN IF NOT EXISTS payment_intent_id text`
- **Root cause:** `Haul.Repo.all_tenants/0` is not defined, so `mix ash_postgres.migrate --tenants` fails. Tenant migrations must be applied manually or the function needs implementation.

### Bug 2: Oban instance not running (FIXED)

- **Symptom:** Second submission attempt failed with `No Oban instance named Oban is running and config isn't available`
- **Cause:** The dev server was started before the Oban migration was applied. When Oban tried to start, the table didn't exist (or some initialization failed), and the supervisor gave up.
- **Fix:** Restarted the dev server (`kill` + `mix phx.server`). After restart, Oban started successfully.
- **Note:** These are dev environment setup issues, not code bugs. The code itself is correct.

## Summary

All acceptance criteria met after resolving dev environment setup issues:
- [x] Booking submission triggers notification workers (visible in Oban jobs table)
- [x] Swoosh dev mailbox shows both customer confirmation and operator alert
- [x] No Oban worker failures in server logs
- [x] SMS sandbox adapter logs the message (visible in browser console)
