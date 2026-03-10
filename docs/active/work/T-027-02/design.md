# T-027-02 Design: Resource Factories

## Decision: Extend `Haul.Test.Factories` with resource builders

### Approach

Add `build_*` functions to the existing `Haul.Test.Factories` module. Each function:
- Takes `tenant` as first arg (matches existing `build_user/2` convention)
- Takes optional `attrs` map for overrides (default `%{}`)
- Provides sensible defaults with unique values where needed
- Uses `Ash.Changeset.for_create` → `Ash.create!` with `authorize?: false`
- Returns the created resource (not `{:ok, resource}`)

### Why not a separate module?

The existing `Haul.Test.Factories` is already imported/delegated everywhere. Adding resource factories here keeps one import path. The module stays under 200 lines with all six factories.

### Factory Signatures

```elixir
build_service(tenant, attrs \\ %{})      # → Service
build_gallery_item(tenant, attrs \\ %{}) # → GalleryItem
build_endorsement(tenant, attrs \\ %{})  # → Endorsement
build_site_config(tenant, attrs \\ %{})  # → SiteConfig
build_page(tenant, attrs \\ %{})         # → Page
build_job(tenant, attrs \\ %{})          # → Job
```

### Default Values

| Factory | Defaults |
|---------|----------|
| build_service | title: "Test Service #{n}", description: "Test service description", icon: "truck" |
| build_gallery_item | before_image_url: "/uploads/test/before.jpg", after_image_url: "/uploads/test/after.jpg" |
| build_endorsement | customer_name: "Test Customer #{n}", quote_text: "Great service!" |
| build_site_config | business_name: "Test Business", phone: "555-0100" |
| build_page | slug: "test-page-#{n}", title: "Test Page #{n}", body: "Test content" |
| build_job | customer_name: "Test Customer #{n}", customer_phone: "555-0100", address: "123 Test St", item_description: "Old couch" |

Using `System.unique_integer([:positive])` for `#{n}` — same pattern as existing `build_company`.

### SiteConfig Singleton Handling

SiteConfig is one-per-tenant. The factory uses `:create_default` action. If tests need to customize, they pass attrs. No upsert logic needed — each test has its own sandbox or shared tenant context. Tests that need SiteConfig just call `build_site_config(tenant, %{business_name: "Custom"})`.

### Migration Strategy

Pick 5-10 files with the most boilerplate:
1. `test/haul/content/service_test.exs` — replace inline creation
2. `test/haul/content/gallery_item_test.exs` — replace @valid_attrs pattern
3. `test/haul/content/endorsement_test.exs` — replace @valid_attrs pattern
4. `test/haul/content/page_test.exs` — replace @valid_attrs pattern
5. `test/haul/operations/job_test.exs` — replace @valid_attrs pattern
6. `test/haul_web/live/app/services_live_test.exs` — replace private helper
7. `test/haul_web/live/app/gallery_live_test.exs` — replace private helper
8. `test/haul_web/live/app/endorsements_live_test.exs` — replace private helper

### What NOT to add

- No factory for `Conversation` — only used in 1-2 files
- No factory for `AdminUser` — already handled by `build_admin_session`
- No `build_and_associate` helpers — keep factories simple, let tests compose

### Rejected Alternatives

1. **ExMachina-style factory library** — adds a dependency for simple wrapper functions. Overkill.
2. **Separate factory modules per domain** — unnecessary indirection for 6 functions.
3. **Builder pattern with chaining** — over-engineered for this scale.
