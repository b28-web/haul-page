# T-027-02 Review: Resource Factories

## Test Suite Result

`mix test` — **845 tests, 0 failures** (37.9s)

## Summary of Changes

### Files Modified

| File | Change |
|------|--------|
| `test/support/factories.ex` | Added 6 resource factory functions (`build_service`, `build_gallery_item`, `build_endorsement`, `build_site_config`, `build_page`, `build_job`), resource aliases, expanded `@moduledoc` |
| `test/support/conn_case.ex` | Added `import Haul.Test.Factories` to `using` block |
| `test/haul/content/service_test.exs` | Simplified setup (factory helpers), replaced 3 creation-as-setup calls with `build_service` |
| `test/haul/content/gallery_item_test.exs` | Simplified setup, replaced 1 creation-as-setup call with `build_gallery_item` |
| `test/haul/content/endorsement_test.exs` | Simplified setup |
| `test/haul/content/page_test.exs` | Simplified setup, replaced 4 creation-as-setup calls with `build_page` |
| `test/haul/content/site_config_test.exs` | Simplified setup, replaced 2 creation-as-setup calls with `build_site_config` |
| `test/haul/operations/job_test.exs` | Simplified setup |
| `test/haul_web/live/app/services_live_test.exs` | Removed `create_service/2` helper, replaced 7 calls with `build_service` |
| `test/haul_web/live/app/gallery_live_test.exs` | Removed `create_item/2` helper, replaced 9 calls with `build_gallery_item` |
| `test/haul_web/live/app/endorsements_live_test.exs` | Removed `create_endorsement/2` helper, replaced 10 calls with `build_endorsement` |

**Total: 11 files modified, 0 files created, 0 files deleted.**

## Acceptance Criteria Verification

- [x] `build_service(tenant, attrs)` — creates Service with defaults (title, description, icon)
- [x] `build_gallery_item(tenant, attrs)` — creates GalleryItem with defaults (before/after URLs)
- [x] `build_endorsement(tenant, attrs)` — creates Endorsement with defaults (customer_name, quote_text)
- [x] `build_site_config(tenant, attrs)` — creates SiteConfig with defaults (business_name, phone)
- [x] `build_job(tenant, attrs)` — creates Job in :lead state with defaults
- [x] `build_page(tenant, attrs)` — creates Page with defaults (slug, title, body)
- [x] Each factory provides sensible defaults overridable via `attrs`
- [x] Defaults use unique values where needed (Service title, Page slug, Customer name, Job customer_name)
- [x] 9 test files migrated (5 content domain + 1 operations + 3 LiveView)
- [x] `@moduledoc` documents factory usage
- [x] All factories use Ash actions (not raw Ecto) with `authorize?: false`

## Design Decisions

1. **Kept `@valid_attrs` in domain tests** — Tests that directly test creation actions (validation, required fields) still use inline `Ash.Changeset.for_create` calls. Replacing those with factory calls would hide the thing being tested. The factory is used for creation-as-setup only.

2. **Added Factories import to ConnCase** — Rather than using fully qualified `Haul.Test.Factories.build_*()` in LiveView tests, added the import to ConnCase's `using` block. Matches the existing DataCase pattern.

3. **Setup simplification** — All 6 domain test files had identical 12-line setup blocks for company creation + tenant provisioning + on_exit cleanup. Reduced to 3 lines using `build_company`/`provision_tenant`/`cleanup_all_tenants`.

## Test Coverage

All 6 factories are exercised across 9 migrated test files (33+ individual test cases). No new test file was needed — the factories are tested implicitly by the migrated tests.

## Open Concerns

None. All acceptance criteria met. No regressions.
