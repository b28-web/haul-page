# T-033-04 Plan: Dedup QA Tests

## Step 1: Delete superadmin_qa_test.exs
- Delete `test/haul_web/live/admin/superadmin_qa_test.exs`
- Run `mix test test/haul_web/live/admin/ --stale` to verify no breakage
- **Verify:** 18 tests removed, 0 coverage loss

## Step 2: Merge domain_qa → domain_settings_live
- Read domain_settings_live_test.exs fully
- Add 1 unique test: PubSub `domain_status_changed` updates UI to active
- Delete domain_qa_test.exs
- Run `mix test test/haul_web/live/app/domain_settings_live_test.exs`
- **Verify:** domain_settings has 18 tests, all pass

## Step 3: Merge billing_qa → billing_live
- Read billing_live_test.exs fully
- Add 4 unique tests:
  - Feature gate: Starter plan domain page shows upgrade prompt
  - Feature gate: Pro plan domain page shows custom domain form
  - Downgrade: after downgrade, domain settings shows upgrade prompt
  - Dunning: shows payment issue warning when dunning_started_at set
- Copy `set_company_plan` helper if not already in billing_live
- Delete billing_qa_test.exs
- Run `mix test test/haul_web/live/app/billing_live_test.exs`
- **Verify:** billing_live has 19 tests, all pass

## Step 4: Merge proxy_qa → proxy_routes
- Read proxy_routes_test.exs fully
- Extend setup to create companies with SiteConfig + Service data (like proxy_qa setup does)
- Add 6 unique tests across existing and new describe blocks
- Delete proxy_qa_test.exs
- Run `mix test test/haul_web/plugs/proxy_routes_test.exs`
- **Verify:** proxy_routes has 13 tests, all pass

## Step 5: Merge onboarding_qa → onboarding_live
- Read onboarding_live_test.exs fully
- Add `Haul.Onboarding.run/1` setup within new describe blocks
- Add 6 unique tests in 2 new describe blocks
- Delete onboarding_qa_test.exs
- Run `mix test test/haul_web/live/app/onboarding_live_test.exs`
- **Verify:** onboarding_live has 20 tests, all pass

## Step 6: Merge chat_qa → chat_live
- Read chat_live_test.exs fully
- Add 9 unique tests in 5 new describe blocks
- Preserve `Process.sleep` patterns for async handling
- Delete chat_qa_test.exs
- Run `mix test test/haul_web/live/chat_live_test.exs`
- **Verify:** chat_live has 30 tests, all pass

## Step 7: Merge provision_qa → preview_edit
- Read preview_edit_test.exs fully
- Port `@profile` module attribute and `provision_and_enter_edit_mode` helper
- Add 9 unique tests across 5 new/existing describe blocks
- Port tenant cleanup from on_exit
- Delete provision_qa_test.exs
- Run `mix test test/haul_web/live/preview_edit_test.exs`
- **Verify:** preview_edit has 22 tests, all pass

## Step 8: Full suite verification
- Run `mix test` — full suite
- Verify total test count decreased by 75
- Run `mix haul.test_pyramid` to show improved ratios
- Record results in progress.md

## Testing Strategy
- After each merge: run the target file to verify merged tests pass
- After all merges: run `mix test --stale` then `mix test`
- No new test files created — only modifications and deletions
