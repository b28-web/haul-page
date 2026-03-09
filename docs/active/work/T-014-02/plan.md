# T-014-02 Plan: Default Content Pack

## Step 1: Create gallery SVG placeholders
- Create `priv/static/images/gallery/before-4.svg` and `after-4.svg`
- Match existing SVG style (simple colored rectangles with text labels)
- Verify: files exist and are valid SVG

## Step 2: Create default content pack files
- Create `priv/content/defaults/` directory structure
- Write `site_config.yml` with generic placeholder values
- Write 6 service YAML files matching ticket spec
- Write 3 sample endorsement YAML files with "(Sample)" marker
- Write 4 gallery YAML files referencing SVG placeholders
- Write 2 generic markdown pages (about, faq)
- Verify: all files parse with YamlElixir / frontmatter parser

## Step 3: Update Onboarding to use defaults
- Modify `lib/haul/onboarding.ex` `seed_content/1` to pass defaults path
- Add `defaults_content_root/0` private function
- Verify: `mix compile` passes

## Step 4: Update existing tests
- Update `test/haul/onboarding_test.exs` assertions for new content counts
- Verify: `mix test test/haul/onboarding_test.exs` passes

## Step 5: Add defaults validation test
- Create `test/haul/content/defaults_test.exs`
- Test: all expected files exist
- Test: all YAML files parse successfully
- Test: all markdown pages have valid frontmatter
- Test: correct counts (6 services, 3 endorsements, 4 gallery, 2 pages)
- Verify: `mix test test/haul/content/defaults_test.exs` passes

## Step 6: Run full test suite
- `mix test` — all tests pass
- Verify no regressions in existing content seeding

## Testing strategy
- **Unit:** defaults_test.exs validates file structure and parseability
- **Integration:** onboarding_test.exs exercises full seed flow with defaults
- **Regression:** full test suite ensures existing content paths unaffected
