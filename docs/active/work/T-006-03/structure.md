# T-006-03 Structure: seed-task

## New Files

### lib/mix/tasks/haul/seed_content.ex
Module: `Mix.Tasks.Haul.SeedContent`
- `@shortdoc "Seed content resources from priv/content/ files"`
- `run/1` — starts app, finds all companies, calls Seeder for each tenant
- Outputs summary per tenant

### lib/haul/content/seeder.ex
Module: `Haul.Content.Seeder`
- Public API:
  - `seed!(tenant)` — seeds all content types for a tenant, returns summary map
- Private functions:
  - `seed_site_config(tenant)` — reads site_config.yml, upserts SiteConfig
  - `seed_services(tenant)` — reads services/*.yml, upserts Services
  - `seed_gallery_items(tenant)` — reads gallery/*.yml, upserts GalleryItems
  - `seed_endorsements(tenant)` — reads endorsements/*.yml, upserts Endorsements
  - `seed_pages(tenant)` — reads pages/*.md, parses frontmatter + body, upserts Pages
  - `parse_frontmatter(content)` — splits YAML frontmatter from markdown body
  - `content_path(relative)` — resolves path under priv/content/
  - `upsert(resource, match_field, attrs, tenant)` — generic upsert helper

### priv/content/site_config.yml
Single YAML file with SiteConfig fields.

### priv/content/services/ (6 files)
- junk-removal.yml
- furniture-pickup.yml
- appliance-hauling.yml
- yard-waste.yml
- construction-debris.yml
- estate-cleanout.yml

Each contains: title, description, icon, sort_order

### priv/content/endorsements/ (4 files)
- jane-d.yml, mike-r.yml, sarah-k.yml, tom-b.yml

Each contains: customer_name, quote_text, star_rating, source, date, featured

### priv/content/gallery/ (3 files)
- garage-cleanout.yml, backyard-debris.yml, office-furniture.yml

Each contains: before_image_url, after_image_url, caption, alt_text, sort_order, featured

### priv/content/pages/ (2 files)
- about.md — About Us page with YAML frontmatter
- faq.md — FAQ page with YAML frontmatter

### test/haul/content/seeder_test.exs
- Tests `Haul.Content.Seeder.seed!/1` end-to-end
- Verifies record counts after seeding
- Verifies idempotency (run twice)
- Verifies Page body_html is rendered
- Verifies SiteConfig values

## Modified Files

### mix.exs
- Add `{:yaml_elixir, "~> 2.11"}` to deps
- Add `"haul.seed_content"` to setup alias (after ecto.setup)

## Module Boundaries

```
Mix.Tasks.Haul.SeedContent
  └── calls Haul.Content.Seeder.seed!(tenant)
        ├── reads YAML files from priv/content/
        ├── calls Ash.create / Ash.update on Content resources
        └── returns {:ok, summary} or raises on error

Haul.Content.Seeder
  ├── depends on: YamlElixir, Haul.Content.* resources, Ash
  ├── reads from: priv/content/ directory
  └── writes to: DB via Ash actions
```

## Data Flow

```
priv/content/site_config.yml  →  YamlElixir.read_from_file!  →  SiteConfig :create_default / :edit
priv/content/services/*.yml   →  YamlElixir.read_from_file!  →  Service :add / :edit
priv/content/gallery/*.yml    →  YamlElixir.read_from_file!  →  GalleryItem :add / :edit
priv/content/endorsements/*.yml → YamlElixir.read_from_file! →  Endorsement :add / :edit
priv/content/pages/*.md       →  parse_frontmatter + YamlElixir →  Page :draft / :edit
```

## File Organization

```
lib/
├── mix/tasks/haul/
│   └── seed_content.ex          # NEW — mix task shell
├── haul/content/
│   ├── seeder.ex                # NEW — seeding logic
│   ├── site_config.ex           # existing
│   ├── service.ex               # existing
│   ├── gallery_item.ex          # existing
│   ├── endorsement.ex           # existing
│   └── page.ex                  # existing
priv/content/
├── site_config.yml              # NEW
├── services/                    # NEW directory
├── endorsements/                # NEW directory
├── gallery/                     # NEW directory
├── pages/                       # NEW directory
├── gallery.json                 # existing (legacy)
└── endorsements.json            # existing (legacy)
test/haul/content/
└── seeder_test.exs              # NEW
```
