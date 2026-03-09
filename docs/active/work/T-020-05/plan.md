# T-020-05 Plan: Browser QA — AI Provision Pipeline

## Step 1: Create test file with setup

Create `test/haul_web/live/provision_qa_test.exs` with:
- Module setup: clear sandbox/rate limits, on_exit tenant cleanup
- @profile module attribute with complete OperatorProfile
- `provision_and_enter_edit_mode/1` helper (mirrors preview_edit_test.exs pattern)

## Step 2: Full pipeline tests

- "chat UI renders at /start": mount, verify header, input, sidebar
- "provisioning enters edit mode": trigger provision, verify preview panel
- "shows building message": verify provisioning state message

## Step 3: Edit flow tests

- "tagline edit via chat updates SiteConfig": send "Change the tagline", verify DB update
- "phone edit via chat updates SiteConfig": send "Change phone to 555-8888", verify DB
- "edit count tracks": verify counter increments

## Step 4: Go live + tenant site verification

- "go live finalizes and shows admin link": click go_live, verify finalized state
- "tenant landing page renders with generated content": GET / with tenant context, verify business_name, services
- "tenant scan page renders": GET /scan with tenant context
- "tenant booking form renders": GET /book with tenant context

## Step 5: Mobile UX

- "mobile preview toggle in edit mode": toggle show/hide preview panel

## Step 6: Run tests, fix issues

```bash
mix test test/haul_web/live/provision_qa_test.exs
```

## Verification Criteria

- All tests pass
- Full pipeline path covered: chat → extract → provision → preview → edit → go live → tenant site
- Tenant site pages render with real generated content (not placeholders)
- No test pollution (tenant schemas cleaned up)
