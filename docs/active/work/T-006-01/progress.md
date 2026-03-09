# T-006-01 Progress: Content Resources

## Step 1: Domain Module + Enum Type — DONE
- Created `lib/haul/content.ex` (Ash Domain with all 5 resources + 5 PaperTrail Version resources)
- Created `lib/haul/content/endorsement/source.ex` (Ash.Type.Enum)

## Step 2: Create All Five Resources — DONE
- `lib/haul/content/site_config.ex` — singleton, create_default + edit actions, code_interface
- `lib/haul/content/service.ex` — sort_order preparation, add + edit actions
- `lib/haul/content/gallery_item.ex` — before/after images, featured flag
- `lib/haul/content/endorsement.ex` — star_rating 1-5, source enum, optional belongs_to :job
- `lib/haul/content/page.ex` — slug identity, draft/edit/publish/unpublish, body_html stub rendering

### Deviations from plan:
- AshPaperTrail requires `paper_trail do change_tracking_mode :changes_only end` block — not in spec
- AshPaperTrail auto-creates Version resources that must be registered in the domain
- Page `:edit` action needs `require_atomic? false` due to inline change function

## Step 3: Register Domain in Config — DONE
- Added `Haul.Content` to `ash_domains` in `config/config.exs`

## Step 4: Compile — DONE
- Zero warnings, zero errors with `--warnings-as-errors`

## Step 5: Generate Migrations — DONE
- Generated `priv/repo/tenant_migrations/20260309010916_create_content.exs`
- 10 tables created: 5 resource tables + 5 version tables
- 10 resource snapshots created

## Step 6: Run Migrations — DONE
- Base migrations already up (tenant migrations apply on provisioning)

## Step 7: Write Tests — DONE
- 5 test files in `test/haul/content/`:
  - site_config_test.exs (4 tests)
  - service_test.exs (6 tests)
  - gallery_item_test.exs (4 tests)
  - endorsement_test.exs (8 tests)
  - page_test.exs (6 tests)
- Total: 28 new content tests

## Step 8: Run Tests — DONE
- 113 total tests pass (28 new + 79 existing + 6 from other new tickets)
- No regressions
