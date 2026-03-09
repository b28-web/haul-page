# T-006-03 Progress: seed-task

## Completed

1. **yaml_elixir dependency** — Added `{:yaml_elixir, "~> 2.11"}` to mix.exs, fetched (v2.12.1)
2. **Seed data files created** — All YAML/markdown files in priv/content/:
   - `site_config.yml` — realistic operator config
   - `services/` — 6 service files (junk-removal, furniture-pickup, appliance-hauling, yard-waste, construction-debris, estate-cleanout)
   - `endorsements/` — 4 endorsement files (jane-d, mike-r, sarah-k, tom-b)
   - `gallery/` — 3 gallery item files (garage-cleanout, backyard-debris, office-furniture)
   - `pages/` — 2 markdown pages with YAML frontmatter (about.md, faq.md)
3. **Haul.Content.Seeder module** — `lib/haul/content/seeder.ex`
   - `seed!(tenant)` orchestrates all seeding
   - Upserts by natural key per resource (title, slug, before_image_url, customer_name)
   - Handles YAML frontmatter parsing for .md pages
   - Filters update attrs to only those accepted by `:edit` actions
4. **Mix task** — `lib/mix/tasks/haul/seed_content.ex` (`mix haul.seed_content`)
   - Seeds all companies' tenant schemas
   - Outputs summary per tenant
5. **Setup alias updated** — `haul.seed_content` added to `mix setup` after `ecto.setup`
6. **Tests** — `test/haul/content/seeder_test.exs` (4 tests)
   - Creates all expected records (1 SiteConfig, 6 services, 3 gallery, 4 endorsements, 2 pages)
   - Idempotency verified (run twice, all :updated, no duplicate records)
   - Frontmatter parsing tested
   - Invalid frontmatter error tested

## Deviations from plan

- Had to filter attrs for `:edit` actions — GalleryItem `:edit` doesn't accept `before_image_url`/`after_image_url`, Page `:edit` doesn't accept `:slug`. Added `Map.drop` before update calls.

## Test results

- Seeder tests: 4/4 passing
- Full suite: 132/132 passing (was 128 before, +4 new tests)
