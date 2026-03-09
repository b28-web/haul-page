# T-006-03 Review: seed-task

## Summary

Built `mix haul.seed_content` — an idempotent mix task that reads YAML/markdown files from `priv/content/` and upserts them into Ash content resources (SiteConfig, Service, GalleryItem, Endorsement, Page) for all tenant schemas.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul/content/seeder.ex` | Core seeding logic — reads files, upserts records |
| `lib/mix/tasks/haul/seed_content.ex` | Mix task shell — starts app, iterates tenants |
| `test/haul/content/seeder_test.exs` | 4 tests: creation, idempotency, frontmatter parsing |
| `priv/content/site_config.yml` | Operator config seed data |
| `priv/content/services/*.yml` | 6 service definitions |
| `priv/content/endorsements/*.yml` | 4 customer endorsements |
| `priv/content/gallery/*.yml` | 3 before/after gallery items |
| `priv/content/pages/about.md` | About Us page (YAML frontmatter + markdown) |
| `priv/content/pages/faq.md` | FAQ page (YAML frontmatter + markdown, includes GFM table) |

## Files Modified

| File | Change |
|------|--------|
| `mix.exs` | Added `yaml_elixir ~> 2.11` dep; added `haul.seed_content` to setup alias |

## Acceptance Criteria Checklist

- [x] Mix task `mix haul.seed_content` exists and is idempotent
- [x] Reads `priv/content/site_config.yml` → upserts SiteConfig singleton
- [x] Reads `priv/content/services/*.yml` → upserts Service records (matched by title)
- [x] Reads `priv/content/endorsements/*.yml` → upserts Endorsement records
- [x] Reads `priv/content/gallery/*.yml` → upserts GalleryItem records
- [x] Reads `priv/content/pages/*.md` → parses YAML frontmatter + markdown body, upserts Page records (matched by slug)
- [x] `yaml_elixir` added to deps
- [x] Dev seed files created with realistic content matching the mockup (6 services, 4 endorsements, 3 gallery items, 2 pages)
- [x] `mix setup` alias includes `haul.seed_content`

## Test Coverage

- **4 new tests** in `test/haul/content/seeder_test.exs`
  - `seed!/1` creates all content resources from seed files — verifies counts and field values
  - `seed!/1` idempotency — runs twice, verifies all return `:updated`, no duplicate records
  - `parse_frontmatter!/1` — splits YAML from markdown body correctly
  - `parse_frontmatter!/1` — raises on invalid format
- **132 total tests passing** (up from 128)

## Design Decisions

1. **Seeder as separate module** — Mix task is a thin shell, `Haul.Content.Seeder` contains testable logic
2. **One file per record** — Each service/endorsement/gallery/page is a separate YAML/markdown file for easier management
3. **Seed all tenants** — Task iterates all Company records, seeds content into each tenant schema
4. **Natural key matching** — Services by title, GalleryItems by before_image_url, Endorsements by customer_name, Pages by slug
5. **Filtered update attrs** — `:edit` actions don't accept all fields (e.g., GalleryItem `:edit` rejects URL fields), so update attrs are filtered

## Open Concerns

1. **Legacy Content.Loader** — `lib/haul/content/loader.ex` and its JSON files (`gallery.json`, `endorsements.json`) still exist. Can be deprecated once templates query Ash resources instead of persistent_term. Not in scope for this ticket.
2. **Endorsement matching by customer_name alone** — Not truly unique. Fine for seed data, but a composite key (name + quote) would be safer. No practical issue now.
3. **No `--tenant` flag** — Task seeds all tenants. A flag for single-tenant seeding could be useful later but is not in acceptance criteria.
4. **AshPaperTrail audit records** — Seeding creates paper trail entries. Acceptable for dev/staging; in production you might want to skip audit for bulk seeds. Not a concern now.
5. **"Why us" items** — Ticket mentions "6 'why us' items" but there's no WhyUs resource. The 6 services fulfill that role in the current design.
