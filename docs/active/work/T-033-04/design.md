# T-033-04 Design: Dedup QA Tests

## Decision: Merge unique tests into non-QA counterparts, delete all QA files

### Approach

For each QA file:
1. Identify truly unique tests (not covered by non-QA counterpart assertions)
2. Move unique tests into the appropriate `describe` block in the non-QA file
3. Adapt setup/helper functions as needed (reuse existing ones in non-QA file)
4. Delete the QA file entirely

### Why not keep any QA files?

- All 7 QA files use the same test framework (`Phoenix.LiveViewTest`) as non-QA
- No QA file has >9 unique tests — all fit within existing non-QA files
- The "QA" label is misleading since there are no real browser/Playwright tests
- Merging consolidates related tests, making it easier to maintain coverage

### File-by-file plan

#### 1. superadmin_qa_test.exs → DELETE (0 unique)
- All 18 tests duplicated across accounts_live_test.exs, impersonation_test.exs, security_test.exs
- No merge needed, just delete

#### 2. domain_qa_test.exs → MERGE 1, DELETE
- 1 unique: PubSub `domain_status_changed` updates UI
- Target: domain_settings_live_test.exs, new `describe "PubSub status updates"`
- Non-QA file has 17 tests, will become 18 — well within 30-test limit

#### 3. billing_qa_test.exs → MERGE 4, DELETE
- 4 unique: 2 cross-page feature gates, 1 downgrade→domain cross-page, 1 dunning alert
- Target: billing_live_test.exs
- Cross-page feature gate tests go in new `describe "feature gate cross-verification"`
- Dunning alert goes in new `describe "dunning alerts"`
- Non-QA file has 15 tests, will become 19 — fine

#### 4. proxy_qa_test.exs → MERGE 6, DELETE
- 6 unique: tagline/area rendering, form validate, chat under proxy, phone isolation, WebSocket re-render, booking interaction
- Target: proxy_routes_test.exs
- Add to existing describe blocks where appropriate
- Non-QA file has 7 tests, will become 13 — fine

#### 5. chat_qa_test.exs → MERGE 9, DELETE
- 9 unique: multi-turn conversation, CSS alignment, typing indicator, mobile toggle (2), provisioning (3), conversation persistence
- Target: chat_live_test.exs
- Add new describe blocks: "multi-turn conversation", "mobile profile toggle", "provisioning flow", "conversation persistence"
- Non-QA file has 21 tests, will become 30 — at the limit but acceptable since these are distinct flows

#### 6. provision_qa_test.exs → MERGE 9, DELETE
- 9 unique: pre-provision chat, building message, edit instructions, service add with DB verify, 3 cross-page tenant verifications, edit persistence, mobile preview toggle
- Target: preview_edit_test.exs
- Non-QA file has 13 tests, will become 22 — fine
- The `provision_and_enter_edit_mode` helper and `@profile` module attribute must be adapted to match non-QA setup

#### 7. onboarding_qa_test.exs → MERGE 6, DELETE
- 6 unique: content pack services, gallery rendering, gallery captions, endorsement quotes, booking form, content quality
- Target: onboarding_live_test.exs
- Add new describe blocks: "onboarded content quality", "public pages after onboarding"
- Non-QA file has 14 tests, will become 20 — fine
- Requires Haul.Onboarding.run/1 setup (currently in QA but not in non-QA)

### Rejected alternatives

1. **Keep QA files as separate "integration" tier** — rejected because they're the same tier (ConnCase + LiveViewTest), just duplicated
2. **Rename QA files to drop `_qa` suffix** — rejected because it doesn't eliminate duplication
3. **Delete unique QA tests rather than merging** — rejected because it loses coverage

### Risks

- **Test count in chat_live_test.exs reaches 30** — at the ticket's suggested limit, but all tests are logically grouped. If needed, split later.
- **Onboarding merge requires adding `Haul.Onboarding.run/1` setup to non-QA file** — changes setup complexity but the test is valuable for verifying the end-to-end onboarding pipeline.
- **Process.sleep patterns** from chat/provision QA tests must be preserved — these are necessary for async message handling.

### Expected outcome

- 7 QA files deleted
- 75 duplicate tests removed
- 35 unique tests merged into 6 non-QA files
- Net test reduction: 75 tests (68%), exceeding 50% target
- All non-QA files remain under 30 tests
