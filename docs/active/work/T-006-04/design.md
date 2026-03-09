# T-006-04 Design: Content-Driven Pages

## Decision: Shared Content Helper Module

### Approach
Create a `HaulWeb.ContentHelpers` module that encapsulates tenant resolution + content querying with fallback logic. All three pages (landing, scan, booking) call this module instead of `Application.get_env(:haul, :operator)`.

### Why not query directly in each controller/LiveView?
- Tenant resolution logic (slug -> schema name) would be duplicated 3 times
- Fallback-to-operator-config logic would be duplicated
- A helper keeps controllers/LiveViews thin

### Why not a plug?
- Landing page uses a controller (conn-based), scan/booking use LiveView (socket-based)
- A plug only works for conn pipeline; LiveView mount is separate
- A helper function works uniformly for both

## Content Loading Strategy

### Primary: Ash resource queries with tenant
```
tenant = resolve_tenant()
site_config = SiteConfig |> Ash.read!(tenant: tenant) |> List.first()
services = Service |> Ash.read!(tenant: tenant)
```

### Fallback: Operator config (existing behavior)
If Ash query returns no results (empty DB, no seeding done), fall back to `Application.get_env(:haul, :operator)`. This satisfies the "graceful with fallback copy" acceptance criterion.

### Field Name Normalization
GalleryItem uses `before_image_url`/`after_image_url` but scan template expects `before_photo_url`/`after_photo_url`. Two options:
1. **Rename template fields** to match Ash resource — cleaner, no mapping layer
2. Map Ash struct fields to template-expected names

**Decision:** Option 1 — update the template to use `before_image_url`/`after_image_url`. The Ash resource field names are the source of truth.

## Tenant Resolution
Use operator `slug` from config to derive tenant schema name, same as BookingLive already does:
```elixir
operator = Application.get_env(:haul, :operator, [])
tenant = ProvisionTenant.tenant_schema(operator[:slug] || "default")
```

## Loader Deprecation
- Keep `Loader` module and `Loader.load!()` call in Application for now — removing it is a separate cleanup
- The scan page will stop calling it; if nothing else references it, it becomes dead code
- Clean removal can happen in a follow-up ticket

## Test Strategy
- Tests need a seeded tenant with content resources
- Create a shared test helper or inline setup that provisions a tenant and seeds content
- Tests assert against seeded data instead of operator config data
- Keep existing test structure (section headings, tel: links, etc.)

## Rejected Alternatives

### GenServer cache layer
Overkill — Ash reads are fast, pages are low-traffic. No caching needed beyond what Ecto provides.

### Assign via plug + on_mount
Split approach (plug for controller, on_mount for LiveView) adds complexity for the same result. Single helper function is simpler.

### Remove operator config entirely
Too aggressive for this ticket. Operator config is still used as fallback and may be referenced elsewhere. Keep it as the fallback layer.
