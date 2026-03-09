# T-006-05 Plan: Browser QA for Content Domain

## Prerequisites

1. Verify dev server is running at localhost:4000 (check with health endpoint)
2. Check if tenant is provisioned and content is seeded
3. If not seeded, run `mix haul.seed_content`

## Execution Steps

### Step 1: Verify dev server

- Fetch `http://localhost:4000/healthz` or navigate to `/`
- If server not running, start with `just dev`

### Step 2: Ensure content is seeded

- Navigate to `/` — if services grid shows seed data titles, seeding is done
- If fallback data (from operator config), run `mix haul.seed_content`

### Step 3: Landing page content verification

- Navigate to `http://localhost:4000/`
- Take snapshot
- Verify in snapshot:
  - "Junk & Handy" business name
  - "(555) 123-4567" phone
  - All 6 service titles from seed data
  - Service descriptions present
  - "We haul it all" tagline
- Record PASS/FAIL

### Step 4: Scan page gallery verification

- Navigate to `http://localhost:4000/scan`
- Take snapshot
- Verify:
  - Gallery section with before/after pairs
  - Captions from seed data (e.g., "Garage cleanout", "Backyard debris", "Office furniture")
  - Image elements present (may show placeholder if URLs 404 — that's OK)
- Record PASS/FAIL

### Step 5: Scan page endorsements verification

- In same snapshot from Step 4, verify:
  - Customer names: Jane D., Mike R., Sarah K., Tom B.
  - Star ratings (filled star icons)
  - Quote text visible
  - Source labels (Google, Yelp, Direct)
- Record PASS/FAIL

### Step 6: Booking page SiteConfig verification

- Navigate to `http://localhost:4000/book`
- Take snapshot
- Verify:
  - "Junk & Handy" business name
  - "(555) 123-4567" phone
- Record PASS/FAIL

### Step 7: Markdown pages check

- Confirm no route for `/about` or `/faq`
- Document as N/A — Page resources seeded but not routed

### Step 8: Server health check

- Check dev server logs for any 500 errors or template warnings during session
- Record PASS/FAIL

### Step 9: Mobile viewport

- Resize browser to 375×812
- Navigate to `/` and `/scan`
- Verify no horizontal overflow, content stacks properly
- Record PASS/FAIL

### Verification

All steps documented in progress.md with PASS/FAIL per step.
