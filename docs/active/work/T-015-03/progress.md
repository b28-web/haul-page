# T-015-03 Progress: Marketing Landing Page

## Completed

### Step 1: Add `is_platform_host` assign to TenantResolver
- Added `platform_host?/2` public function (with doctests)
- TenantResolver now sets `conn.assigns.is_platform_host` in all paths
- Company match → false; fallback with matching bare domain → true; fallback without match → false

### Step 2: Add controller dispatch logic
- `home/2` checks `conn.assigns[:is_platform_host]`
- Platform host → `marketing/2` (new private function)
- Non-platform host → `operator_home/2` (extracted from original `home/2`)

### Step 3: Create marketing template
- Created `lib/haul_web/controllers/page_html/marketing.html.heex` (~250 lines)
- Sections: sticky nav, hero, features grid (6 cards), how it works (3 steps), pricing table (4 tiers), footer
- Same design system: dark theme, Oswald/Source Sans 3, grayscale, flat
- All CTAs link to `/app/signup`

### Step 4: Fix existing tests
- Page controller tests updated to use subdomain host (`junk-and-handy.localhost`)
- Tests now correctly resolve operator tenant instead of hitting marketing page

### Step 5: Write marketing page tests
- 7 new tests in `test/haul_web/controllers/marketing_page_test.exs`
- Tests use `haulpage.test` as host (matches test base_domain config)
- Covers: hero content, pricing tiers, feature descriptions, CTA links, how-it-works, no operator content, page title

### Step 6: Full test suite
- 346 tests total, 3 failures (all pre-existing in SignupLiveTest from T-015-01 WIP)
- No regressions introduced

## Deviations from plan
- Test base_domain is `haulpage.test` not `localhost` — discovered during debugging. Tests use `haulpage.test` as host for marketing page.
