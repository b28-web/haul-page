# T-027-02 Research: Resource Factories

## Current State

### Existing Factory Infrastructure (T-027-01)
`test/support/factories.ex` — `Haul.Test.Factories` module with:
- `build_company/1` — creates Company with unique name
- `provision_tenant/1` — provisions tenant schema
- `build_user/2` — registers user with JWT
- `build_authenticated_context/1` — full company+tenant+user+token
- `build_admin_session/0` — admin user with JWT
- `cleanup_all_tenants/0` — drops non-shared tenant schemas

Already imported in `DataCase` (`using` block) and delegated in `ConnCase`.

### Resource Definitions

All resources use `:context` multitenancy. Key create actions:

| Resource | Module | Action | Required Attrs |
|----------|--------|--------|---------------|
| Service | `Haul.Content.Service` | `:add` | title, description, icon |
| GalleryItem | `Haul.Content.GalleryItem` | `:add` | before_image_url, after_image_url |
| Endorsement | `Haul.Content.Endorsement` | `:add` | customer_name, quote_text |
| SiteConfig | `Haul.Content.SiteConfig` | `:create_default` | business_name, phone |
| Page | `Haul.Content.Page` | `:draft` | slug, title, body |
| Job | `Haul.Operations.Job` | `:create_from_online_booking` | customer_name, customer_phone, address, item_description |

### Boilerplate Patterns in Tests

Two strategies currently used:
1. **Module-level `@valid_attrs` constants** — service_test, gallery_item_test, endorsement_test, page_test, job_test
2. **Private helper functions with `Map.merge`** — services_live_test, gallery_live_test, endorsements_live_test

### Duplication Analysis

| Resource | Files with inline creation | Total occurrences |
|----------|--------------------------|-------------------|
| Service | service_test, services_live_test, preview_edit_test | ~15 |
| GalleryItem | gallery_item_test, gallery_live_test | ~15 |
| Endorsement | endorsement_test, endorsements_live_test | ~19 |
| SiteConfig | site_config_test, site_config_live_test | ~8 |
| Page | page_test | ~8 |
| Job | job_test | ~7 |

### Test Module Structure

- `DataCase` tests (haul/content/, haul/operations/) — import `Haul.Test.Factories`
- `ConnCase` tests (haul_web/live/) — do NOT import Factories; use `HaulWeb.ConnCase` helpers
- Most LiveView tests already have private helper functions that duplicate factory logic
- Many test files use `shared_test_tenant()` in `setup_all` for the tenant context

### Constraints

- Factories must use `authorize?: false` (ticket requirement)
- Must use Ash actions (not raw Ecto) to ensure validations run
- Unique values needed for: Page slug, Service title (for readability)
- SiteConfig is singleton-per-tenant — factory should handle create-or-update semantics
- Job starts in `:lead` state automatically via state machine
