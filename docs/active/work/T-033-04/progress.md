# T-033-04 Progress: Dedup QA Tests

## Completed Steps

### Step 1: Delete superadmin_qa_test.exs ✓
- Deleted `test/haul_web/live/admin/superadmin_qa_test.exs` (18 tests, all duplicates)
- No merge needed — all 18 tests duplicated across accounts_live, impersonation, security tests

### Step 2: Merge domain_qa → domain_settings_live ✓
- Added 1 unique test (PubSub domain_status_changed) to domain_settings_live_test.exs
- Deleted domain_qa_test.exs (14 tests, 13 duplicate)

### Step 3: Merge billing_qa → billing_live ✓
- Added 4 unique tests to billing_live_test.exs:
  - 2 cross-page feature gate verifications (Starter/Pro → domain page)
  - 1 downgrade→domain cross-page verification
  - 1 dunning alert test
- Deleted billing_qa_test.exs (16 tests, 12 duplicate)

### Step 4: Merge proxy_qa → proxy_routes ✓
- Extended proxy_routes_test.exs with `create_company_with_content` helper
- Added 6 unique tests: tagline/area rendering, form validation under proxy, chat under proxy, cross-tenant isolation (3 tests)
- Changed to `async: false` for tenant cleanup
- Deleted proxy_qa_test.exs (13 tests, 7 duplicate)

### Step 5: Merge onboarding_qa → onboarding_live ✓
- Added "public pages after CLI onboarding" describe block with 6 tests
- Uses `Haul.Onboarding.run/1` setup within the describe block
- Deleted onboarding_qa_test.exs (10 tests, 4 duplicate)

### Step 6: Merge chat_qa → chat_live ✓
- Added 9 unique tests in 5 new describe blocks:
  - multi-turn conversation (1), CSS layout (2), mobile profile toggle (2), provisioning flow (3), conversation persistence (1)
- Deleted chat_qa_test.exs (25 tests, 16 duplicate)

### Step 7: Merge provision_qa → preview_edit ✓
- Added 9 unique tests in 6 new describe blocks:
  - pre-provision state (2), edit instructions (1), multiple edits (1), tenant page verification (3), edit persistence (1), mobile preview toggle (1)
- Deleted provision_qa_test.exs (14 tests, 5 duplicate)

### Step 8: Full suite verification ✓
- `mix test`: 898 tests, 0 failures (77.3s)
- `mix haul.test_pyramid`: 903 tests in 101 files (pyramid counts include excluded)
  - Tier 1 (Unit): 371 (41%)
  - Tier 2 (Resource): 159 (18%)
  - Tier 3 (Integration): 373 (41%)

## Summary
- 7 QA files deleted
- 77 tests removed (from 975 to 898 = 70% reduction of QA tests)
- 35 unique tests merged into 6 non-QA counterpart files
- All tests pass
- Target was ≥50% reduction — achieved 70%
