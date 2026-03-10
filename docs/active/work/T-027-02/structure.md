# T-027-02 Structure: Resource Factories

## Files Modified

### 1. `test/support/factories.ex` — Add resource factory functions

Add aliases at top:
```
alias Haul.Content.{Service, GalleryItem, Endorsement, SiteConfig, Page}
alias Haul.Operations.Job
```

Add 6 public functions after existing `build_admin_session`:
- `build_service/2`
- `build_gallery_item/2`
- `build_endorsement/2`
- `build_site_config/2`
- `build_page/2`
- `build_job/2`

Update `@moduledoc` to document resource factories.

### 2. `test/haul/content/service_test.exs` — Migrate to factory

- Remove inline `Ash.Changeset.for_create(:add, ...)` calls
- Replace with `build_service(tenant, %{...})` calls
- Keep test-specific attr overrides in the `build_service` call

### 3. `test/haul/content/gallery_item_test.exs` — Migrate to factory

- Remove `@valid_attrs` module attribute
- Replace inline creation with `build_gallery_item(tenant, %{...})`

### 4. `test/haul/content/endorsement_test.exs` — Migrate to factory

- Remove `@valid_attrs` module attribute
- Replace inline creation with `build_endorsement(tenant, %{...})`

### 5. `test/haul/content/page_test.exs` — Migrate to factory

- Remove `@valid_attrs` module attribute
- Replace inline creation with `build_page(tenant, %{...})`

### 6. `test/haul/operations/job_test.exs` — Migrate to factory

- Remove `@valid_attrs` module attribute
- Replace inline creation with `build_job(tenant, %{...})`

### 7. `test/haul_web/live/app/services_live_test.exs` — Migrate to factory

- Remove private `create_service/2` helper
- Replace calls with `Haul.Test.Factories.build_service(tenant, %{...})`
- Note: ConnCase doesn't import Factories, so use full module path or add import

### 8. `test/haul_web/live/app/gallery_live_test.exs` — Migrate to factory

- Remove private `create_item/2` helper
- Replace calls with `Haul.Test.Factories.build_gallery_item(tenant, %{...})`

### 9. `test/haul_web/live/app/endorsements_live_test.exs` — Migrate to factory

- Remove private `create_endorsement/2` helper
- Replace calls with `Haul.Test.Factories.build_endorsement(tenant, %{...})`

## ConnCase Import Strategy

ConnCase doesn't import Factories. Two options:
1. Add `import Haul.Test.Factories` to ConnCase `using` block
2. Use fully qualified `Haul.Test.Factories.build_service(...)` in LiveView tests

Option 1 is cleaner — add the import to ConnCase's `using` block. This matches DataCase's approach and avoids verbose calls everywhere.

## No Files Created or Deleted

All changes are modifications to existing files.
