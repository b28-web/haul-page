# T-006-03 Plan: seed-task

## Step 1: Add yaml_elixir dependency

- Add `{:yaml_elixir, "~> 2.11"}` to mix.exs deps
- Run `mix deps.get`
- Verify: `mix deps | grep yaml_elixir` shows it's fetched

## Step 2: Create seed data files

Create all YAML/markdown files in priv/content/:

- `site_config.yml` — realistic operator config
- `services/` — 6 service files with title, description, icon, sort_order
- `endorsements/` — 4 endorsement files with customer_name, quote_text, star_rating, source, date
- `gallery/` — 3 gallery item files with before/after URLs, caption, sort_order
- `pages/` — 2 markdown pages (about.md, faq.md) with YAML frontmatter

Verify: files parse cleanly with `YamlElixir.read_from_file!/1`

## Step 3: Implement Haul.Content.Seeder module

Create `lib/haul/content/seeder.ex`:

- `seed!(tenant)` — orchestrator, calls each seed function, returns summary
- `seed_site_config/1` — read YAML, check existing, create or update
- `seed_services/1` — glob services/*.yml, read each, upsert by title
- `seed_gallery_items/1` — glob gallery/*.yml, read each, upsert by before_image_url
- `seed_endorsements/1` — glob endorsements/*.yml, read each, upsert by customer_name
- `seed_pages/1` — glob pages/*.md, parse frontmatter + body, upsert by slug
- `parse_frontmatter/1` — regex split YAML from markdown body
- Helper for content path resolution

Verify: module compiles (`mix compile`)

## Step 4: Implement Mix Task

Create `lib/mix/tasks/haul/seed_content.ex`:

- `Mix.Tasks.Haul.SeedContent`
- `use Mix.Task`
- `@shortdoc` and `@moduledoc`
- `run/1` — start app, read all companies, seed each tenant
- Output per-tenant summary

Verify: `mix help haul.seed_content` shows the task

## Step 5: Update mix.exs setup alias

Add `"haul.seed_content"` to the setup alias after ecto.setup.

Verify: `mix help setup` shows updated alias

## Step 6: Write tests

Create `test/haul/content/seeder_test.exs`:

- Test `seed!/1` creates expected records (SiteConfig, 6 services, 4 endorsements, 3 gallery items, 2 pages)
- Test idempotency: run `seed!/1` twice, verify same record counts
- Test Page body_html is populated (MDEx rendered)
- Test SiteConfig has expected values

Verify: `mix test test/haul/content/seeder_test.exs` passes

## Step 7: Integration verification

- Run `mix test` — all tests pass (existing + new)
- Run `mix haul.seed_content` against dev DB — verify records created
- Run again — verify idempotent (no errors, no duplicates)

## Testing Strategy

- **Unit:** Seeder module tested directly with real seed files
- **Integration:** Mix task tested by running seeder against test DB
- **Idempotency:** Critical — run twice in same test, assert counts stable
- **Verification criteria:** All acceptance criteria met, all tests green
