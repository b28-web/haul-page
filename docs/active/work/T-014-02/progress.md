# T-014-02 Progress: Default Content Pack

## Completed

### Step 1: Gallery SVG placeholders
- Created `priv/static/images/gallery/before-4.svg` and `after-4.svg`
- Matches existing minimalist style (dark bg, geometric shapes, text label)

### Step 2: Default content pack files
- Created `priv/content/defaults/` with full directory structure
- `site_config.yml` — generic placeholder values ("Your Business Name", etc.)
- 6 service YAMLs: Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help
- 3 endorsement YAMLs: sample-alex, sample-maria, sample-chris — all marked "(Sample)" in customer_name
- 4 gallery YAMLs: kitchen-cleanup, garage-cleanout, yard-debris, office-clearout
- 2 pages: about.md, faq.md — generic, no brand references

### Step 3: Onboarding update
- Modified `lib/haul/onboarding.ex` to seed from `priv/content/defaults/` instead of `priv/content/`
- Added `defaults_content_root/0` private function

### Step 4: Test updates
- Updated `test/haul/onboarding_test.exs` assertions: 6 services, 4 gallery, 3 endorsements

### Step 5: Defaults validation test
- Created `test/haul/content/defaults_test.exs` — 8 tests covering:
  - File existence and counts
  - YAML/frontmatter parsing
  - Service title matching
  - Sample markers in endorsements
  - SVG file reference validation
  - Page slug verification

### Step 6: Full test suite
- 315 tests, 0 failures (up from 258 — new tests from this + other in-progress tickets)

## No deviations from plan
