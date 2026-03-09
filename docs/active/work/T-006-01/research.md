# T-006-01 Research: Content Resources

## Ticket Summary

Define `Haul.Content` Ash domain with five resources: SiteConfig, Service, GalleryItem, Endorsement, Page. Schema-driven content collections equivalent to Astro's `defineCollection`.

## Existing Codebase State

### Domains & Resources Already Defined

Two Ash domains exist, registered in `config/config.exs` under `ash_domains`:

1. **Haul.Accounts** (`lib/haul/accounts.ex`) — Company (public schema), User + Token (tenant-scoped)
2. **Haul.Operations** (`lib/haul/operations.ex`) — Job (tenant-scoped)

All tenant-scoped resources use `multitenancy strategy: :context` in both the resource DSL and the `postgres` block. Schemas are named `tenant_{slug}` and provisioned by `Haul.Accounts.Changes.ProvisionTenant`.

### Resource Conventions Observed

- `uuid_primary_key :id` (not `uuid_v7_primary_key` — the spec doc uses v7 but existing code uses default uuid)
- `@moduledoc false` on all resources
- `public? true` on all public-facing attributes
- `create_timestamp :inserted_at` + `update_timestamp :updated_at`
- Named actions: `:create_company`, `:create_from_online_booking` (not generic `:create`)
- `allow_nil?` explicitly set on each attribute
- No AshPaperTrail in use yet (listed in ticket AC but not in any existing resource)

### Content Bridge Module

`lib/haul/content/loader.ex` — Current bridge that loads gallery/endorsements from JSON files in `priv/content/` into `:persistent_term`. Called at app startup in `application.ex`. This module is explicitly documented as temporary ("will be replaced by Ash resource queries").

Content files: `priv/content/gallery.json`, `priv/content/endorsements.json`.

### Multitenancy Pattern

Content resources should be tenant-scoped (per the content-system design doc — content is per-operator). Same pattern as User/Token/Job:

```elixir
postgres do
  table "table_name"
  repo Haul.Repo
  multitenancy do
    strategy :context
  end
end

multitenancy do
  strategy :context
end
```

Tenant migrations go in `priv/repo/tenant_migrations/`.

### Dependencies

**In mix.exs:**
- `ash ~> 3.19`, `ash_postgres ~> 2.7`, `ash_phoenix ~> 2.3`
- `ash_paper_trail ~> 0.5.7` — installed but unused
- `ash_archival ~> 2.0` — installed but unused
- No `mdex` dependency — needed for Page resource markdown rendering

**Not in mix.exs:**
- `mdex` — required by content-system.md design for Page body_html rendering

### Design Reference

`docs/knowledge/content-system.md` provides complete resource definitions for all five resources. Key design decisions already made:

- SiteConfig: singleton per tenant, `:edit` action only (no create from public API)
- Service: pre-sorted by `sort_order`, pre-filtered to `active == true` via preparations
- GalleryItem: before/after image URLs, featured flag, active flag
- Endorsement: star_rating 1-5, source enum, optional `belongs_to :job`
- Page: slug-based identity, markdown body with cached HTML rendering

### Endorsement → Job Relationship

The spec shows `belongs_to :job, Haul.Operations.Job`. Both resources are tenant-scoped, so this cross-domain reference works — they share the same tenant schema. The Job resource exists in `lib/haul/operations/job.ex`.

### Migration Generation

Ash migrations are generated via `mix ash_postgres.generate_migrations`. Snapshots stored in `priv/resource_snapshots/repo/`. Tenant migration snapshots go under `repo/tenants/`. The migration generation is deterministic based on resource definitions.

### AshPaperTrail

In mix.exs as `ash_paper_trail ~> 0.5.7`. The ticket AC requires it on "all resources." The content-system.md only shows it on SiteConfig and Page. Decision needed: which resources actually need audit trails?

### Existing Config

`config/config.exs` has `ash_domains: [Haul.Accounts, Haul.Operations]`. Must add `Haul.Content` here.

Operator config lives in `config :haul, :operator` — SiteConfig will eventually replace this but for now they coexist.

### Test Patterns

Existing tests in `test/haul_web/` test controllers. Domain-level tests for Accounts/Operations exist in `test/haul/`. Content resource tests should follow the same pattern.

### Open Questions

1. Should MDEx be added as a dependency in this ticket, or deferred?
2. Which resources need AshPaperTrail? AC says "all" but that may be excessive for Service/GalleryItem.
3. SiteConfig singleton: how is the single record ensured? Via application code or DB constraint?
4. Should we remove/update the Content.Loader bridge module in this ticket?
