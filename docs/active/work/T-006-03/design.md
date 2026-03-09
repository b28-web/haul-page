# T-006-03 Design: seed-task

## Decision: Mix Task Architecture

### Option A: Monolithic mix task (all logic in one module)
Simple, single file, easy to follow. Downsides: harder to test individual parsers, longer file.

### Option B: Mix task + separate seeder module
Mix task is a thin shell that calls `Haul.Content.Seeder` which contains the logic. Seeder module is testable without mix task machinery. Each resource type gets a private function.

### Option C: Mix task + per-resource seeder modules
Over-engineered for 5 resource types with simple YAML parsing.

**Decision: Option B** — Mix task delegates to `Haul.Content.Seeder`. The seeder module is unit-testable. The mix task handles CLI concerns (starting the app, logging, error reporting).

## Upsert Strategy

Ash doesn't have built-in upsert-by-natural-key for all resources. Strategy per resource:

### SiteConfig (singleton)
- `Ash.read(SiteConfig, tenant: tenant)` → if empty list, create; if exists, update
- Simple: only one record per tenant

### Service (match by title)
- Read all services for tenant, build a map of title → existing record
- For each seed file: if title exists → `:edit`, else → `:add`

### GalleryItem (match by before_image_url)
- Read all, build map of before_image_url → existing record
- For each seed file: if URL exists → `:edit`, else → `:add`

### Endorsement (match by customer_name)
- Read all, build map of customer_name → existing record
- For each seed file: if name exists → `:edit`, else → `:add`
- Note: customer_name isn't truly unique, but for seed data it's fine

### Page (match by slug — has identity)
- Can use `Ash.get` with slug identity, or read all + map
- For each seed file: if slug exists → `:edit`, else → `:draft`
- The `:draft` action renders markdown; `:edit` also re-renders

## Frontmatter Parsing

For `.md` pages, need to split YAML frontmatter from markdown body:

```
---
key: value
---

body content
```

Regex: `~r/\A---\n(.+?)\n---\n(.*)\z/s` — group 1 is YAML, group 2 is body.

Parse group 1 with `YamlElixir.read_from_string!/1`, body is passed as-is to the `:draft` action.

## YAML File Organization

```
priv/content/
├── site_config.yml          # Single file, one record
├── services/
│   ├── junk-removal.yml     # One file per service
│   ├── furniture-pickup.yml
│   ├── appliance-hauling.yml
│   ├── yard-waste.yml
│   ├── construction-debris.yml
│   └── estate-cleanout.yml
├── endorsements/
│   ├── jane-d.yml           # One file per endorsement
│   ├── mike-r.yml
│   ├── sarah-k.yml
│   └── tom-b.yml
├── gallery/
│   ├── garage-cleanout.yml
│   ├── backyard-debris.yml
│   └── office-furniture.yml
├── pages/
│   ├── about.md             # YAML frontmatter + markdown body
│   └── faq.md
```

**Decision: One file per record.** Easier to manage, add, remove. Filename is documentation.

Alternative considered: single `services.yml` with array. Rejected — harder to manage individual items, filename doesn't communicate content.

## Tenant Selection

The task needs a tenant to seed into. Options:

1. **Seed all tenants** — iterate Company records, seed each
2. **Accept --tenant flag** — seed one specific tenant
3. **Seed default tenant** — use env var or first company

**Decision: Seed all tenants.** Read all Company records, seed content into each tenant schema. This matches the multi-tenant design — every tenant gets the same seed content. In production, this would be the operator's content; in dev, it's sample data.

If no companies exist, log a warning and exit (seeds.exs should have created one).

## Error Handling

- File not found: skip with warning (directory may be empty)
- YAML parse error: raise with filename context
- Ash validation error: raise with resource + attrs context
- Missing required fields: let Ash validation catch it

## Logging

Use `Mix.shell().info/1` for mix task output. Brief: "Seeded 6 services for tenant xyz" style.

## Testing Strategy

Test `Haul.Content.Seeder` directly (not the mix task shell):
1. Create seed files in tmp dir, call seeder functions
2. Verify records created in DB
3. Run again, verify idempotent (no duplicates, updated values)
4. Test frontmatter parsing for pages

Alternative: test with the actual `priv/content/` files. Simpler, tests real data.

**Decision: Test with real priv/content/ files.** The seed files are part of the deliverable. Testing with them validates both the seeder logic and the seed data format.
