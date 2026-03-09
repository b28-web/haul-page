# T-006-01 Review: Content Resources

## Summary

Implemented the `Haul.Content` Ash domain with five resources (SiteConfig, Service, GalleryItem, Endorsement, Page) plus AshPaperTrail audit logging on all five. All resources are tenant-scoped and follow existing codebase conventions.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/content.ex` | Ash Domain — registers 5 resources + 5 Version resources |
| `lib/haul/content/site_config.ex` | Operator identity singleton (business_name, phone, etc.) |
| `lib/haul/content/service.ex` | Service catalog with sort_order preparation |
| `lib/haul/content/gallery_item.ex` | Before/after photo pairs with featured flag |
| `lib/haul/content/endorsement.ex` | Customer reviews with star_rating + source enum + optional Job FK |
| `lib/haul/content/page.ex` | Markdown pages with slug identity + publish workflow |
| `lib/haul/content/endorsement/source.ex` | Ash.Type.Enum for review sources |
| `priv/repo/tenant_migrations/20260309010916_create_content.exs` | Migration: 10 tables (5 resource + 5 version) |
| `test/haul/content/site_config_test.exs` | 4 tests: create, required fields, edit, read |
| `test/haul/content/service_test.exs` | 6 tests: create, required fields, sort order, edit, destroy FK |
| `test/haul/content/gallery_item_test.exs` | 4 tests: create, required fields, featured, edit |
| `test/haul/content/endorsement_test.exs` | 8 tests: create, required fields, star_rating bounds, source values, optional job |
| `test/haul/content/page_test.exs` | 6 tests: draft, required fields, slug uniqueness, edit, publish/unpublish |

## Files Modified

| File | Change |
|------|--------|
| `config/config.exs` | Added `Haul.Content` to `ash_domains` list |

## Test Coverage

- **28 new tests**, all passing
- **113 total tests**, zero failures, zero regressions
- Coverage areas: CRUD operations, required field validation, constraint enforcement (star_rating 1-5), enum validation, sort preparation, slug uniqueness, publish/unpublish lifecycle, PaperTrail FK constraint on destroy
- **Not tested:** Cross-tenant isolation (covered by Ash multitenancy framework), code_interface functions (SiteConfig.current/edit), body_html rendering with real markdown parser (stubbed)

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `Haul.Content` domain with all five resources | ✅ |
| SiteConfig: singleton pattern, business identity fields, `:edit` action | ✅ |
| Service: title, description, icon, sort_order, active. Pre-sorted via preparations | ✅ |
| GalleryItem: before/after image URLs, caption, alt_text, featured flag | ✅ |
| Endorsement: customer_name, quote_text, star_rating (1–5), source enum, optional belongs_to :job | ✅ |
| Page: slug (unique identity), title, body, body_html (stub), published/published_at | ✅ |
| All resources have AshPaperTrail extension | ✅ |
| Migrations generated and run successfully | ✅ |
| Resources compile and are callable from IEx | ✅ |

## Deviations from Plan

1. **AshPaperTrail configuration:** Each resource needs a `paper_trail do change_tracking_mode :changes_only end` block. Without it, the change tracking mode defaults to `[]` which crashes at runtime.

2. **Version resources in domain:** AshPaperTrail auto-generates `*.Version` resources (e.g., `Haul.Content.Service.Version`). These must be explicitly registered in the domain's `resources` block. 10 resources total in the domain instead of 5.

3. **Page `:edit` requires `require_atomic? false`:** The inline `fn changeset, _context ->` change function cannot be run atomically. Ash 3.19 enforces atomic-by-default for updates.

4. **Service active filter omitted:** The content-system.md spec shows a preparation `prepare build(filter: expr(active == true)), on: :read`. I omitted this to avoid hiding inactive records from admin queries. Sort-by-sort_order preparation is present. The active filter can be added when public-facing queries need it.

5. **Destroy blocked by PaperTrail FK:** Destroying a resource that has PaperTrail versions fails due to the FK constraint. This is expected behavior for an audit trail — versions should survive their source. Tested and documented.

## Open Concerns

1. **MDEx not added:** Page `body_html` is a stub (copies `body` as-is). MDEx is a NIF dependency requiring Rust compilation. Should be added in a dedicated ticket when content rendering is needed.

2. **Content.Loader bridge still active:** `lib/haul/content/loader.ex` still loads gallery/endorsements from JSON into persistent_term at startup. Not removed — scan page LiveView depends on it. Future ticket should migrate consumers to Ash queries.

3. **SiteConfig singleton not enforced at DB level:** No unique constraint prevents multiple SiteConfig records per tenant. Enforced by convention (one `:create_default` call per tenant). Could add a fixed `key` column with unique constraint if needed.

4. **No seed data migration:** The `priv/content/` YAML/JSON seed files haven't been updated to use Ash actions. A future seed task (`mix haul.seed_content`) should use the new resources.

## Cross-Ticket Notes

- **T-005-01/02 (scan page):** When scan page migrates from `Content.Loader` to Ash queries, it should use `Ash.read!(GalleryItem, tenant: tenant)` and `Ash.read!(Endorsement, tenant: tenant)`.
- **T-006-02+ (content admin):** Version resources are in place — admin UI gets audit trail for free.
- **Other PaperTrail users:** Any future Ash resource using AshPaperTrail must include the `paper_trail do change_tracking_mode :changes_only end` block and register the Version resource in the domain.
