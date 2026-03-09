# T-011-02 Plan: Customer Seed Content

## Step 1: Parameterize Seeder
- Add `content_root` parameter to `seed!/2` with default
- Thread through all private functions
- Verify existing tests still pass

## Step 2: Update Mix Task
- Add `--operator` flag via OptionParser
- Implement operator-specific path resolution and company find-or-create
- Update @moduledoc with new usage

## Step 3: Create Customer-1 Content Files
- Create `priv/content/operators/customer-1/` directory tree
- Write site_config.yml with distinct business identity
- Write 4 service YAML files
- Write 3 endorsement YAML files
- Write 3 gallery YAML files (placeholder URLs)
- Write about.md and faq.md with customer-specific content

## Step 4: Add Tests
- Test `seed!/2` with custom content root pointing to customer-1 directory
- Test idempotency with custom content root
- Verify existing default content tests still pass unchanged

## Step 5: Verify End-to-End
- Run `mix test` — all tests pass
- Run full test suite to ensure no regressions

## Testing Strategy
- Unit: Seeder with custom content_root
- Integration: Existing seeder_test.exs unchanged (regression)
- No browser tests needed (content renders through existing templates)
