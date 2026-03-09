# T-006-03 Research: seed-task

## Objective

Build `mix haul.seed_content` — reads YAML/markdown files from `priv/content/` and upserts into content Ash resources. Idempotent, integrated into `mix setup`.

## Existing Content Resources

All in `lib/haul/content/`, all multi-tenant (schema-per-tenant via `:context` strategy), all have AshPaperTrail.

### SiteConfig (singleton per tenant)
- **Actions:** `:create_default` (accepts all fields), `:edit`, `:read`
- **Required:** `business_name`, `phone`
- **Defaults:** `coupon_text: "10% OFF"`, `primary_color: "#0f0f0f"`
- **No natural key** — singleton, so read-and-check is sufficient for upsert

### Service
- **Actions:** `:add` (title, description, icon, sort_order), `:edit`, `:read`, `:destroy`
- **Required:** `title`, `description`, `icon`
- **Natural key for matching:** `title` (per acceptance criteria)
- **No uniqueness identity** on title — must query by title for upsert

### GalleryItem
- **Actions:** `:add` (before_image_url, after_image_url, caption, alt_text, sort_order, featured), `:edit`, `:read`
- **Required:** `before_image_url`, `after_image_url`
- **Natural key:** `before_image_url` (unique per photo pair — no identity defined)

### Endorsement
- **Actions:** `:add` (customer_name, quote_text, star_rating, source, date, featured), `:edit`, `:read`
- **Required:** `customer_name`, `quote_text`
- **Natural key:** `customer_name` + `quote_text` composite (no identity defined)
- **Has optional `job_id` FK** — not needed for seeding

### Page
- **Actions:** `:draft` (slug, title, body, meta_description), `:edit`, `:publish`, `:unpublish`, `:read`
- **Required:** `slug`, `title`, `body`
- **Identity:** `unique_slug` on `:slug` — has a proper uniqueness constraint
- **MDEx rendering:** `:draft` and `:edit` auto-render `body` → `body_html` via change functions
- **Matching:** by `slug` (per acceptance criteria)

## Existing Seed Infrastructure

### priv/repo/seeds.exs
Seeds operator config: creates a default Company (tenant root) from env vars. Does NOT seed content.

### priv/content/ (existing files)
- `gallery.json` — 3 gallery items (JSON, not YAML)
- `endorsements.json` — 4 endorsements (JSON, not YAML)
- Used by `Haul.Content.Loader` (legacy bridge module reading JSON into `:persistent_term`)

### Content.Loader (lib/haul/content/loader.ex)
Legacy bridge — reads JSON files, caches in persistent_term. Will be superseded by DB-backed seeding. Can be deprecated after T-006-03.

## Mix Task Conventions

No existing custom mix tasks. Elixir convention: `lib/mix/tasks/haul/seed_content.ex` → `mix haul.seed_content`.

Mix tasks need to `Mix.Task.run("app.start")` to boot the app (Ecto repos, Ash, etc.) before doing work.

## Dependencies

### yaml_elixir
Standard YAML parsing library for Elixir. Needs to be added to `mix.exs`. Provides `YamlElixir.read_from_file!/1` and `YamlElixir.read_from_string!/1`.

### MDEx (already present)
`{:mdex, "~> 0.2"}` — already in deps from T-006-02. Page `:draft` action handles rendering automatically.

## YAML Frontmatter Parsing for Pages

Pages are `.md` files with YAML frontmatter (delimited by `---`). Need to split frontmatter from body, parse frontmatter as YAML, then pass body as markdown to the Page `:draft` action (which renders via MDEx).

Format:
```
---
slug: about
title: About Us
meta_description: Learn about our junk removal service
---

Markdown body here...
```

## Tenant Context for Seeding

All content resources require a tenant. The seed task must:
1. Find existing Company records (or accept a tenant slug as arg)
2. Pass `tenant: tenant` to all Ash operations

The default company is created by `seeds.exs` — seed_content should run after that.

## mix setup Integration

Current aliases:
```elixir
setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"]
ecto.setup: ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]
```

`haul.seed_content` should go after `ecto.setup` (needs DB + migrations + base seed) and before `assets.build`.

## Idempotency Strategy

- **SiteConfig:** Check if any exists → create or skip (singleton)
- **Service:** Query by title → create or update
- **GalleryItem:** Query by before_image_url → create or update
- **Endorsement:** Query by customer_name → create or update (or use composite)
- **Page:** Has `unique_slug` identity — query by slug → create or update

## Key Constraints

1. All operations must include `tenant:` option
2. Page `:draft` renders markdown via MDEx — no need to pre-render
3. Paper trail will record create/update events — acceptable for seeding
4. Endorsement `star_rating` must be 1-5
5. Service `icon` is a hero icon name string
6. No file upload needed — gallery URLs are strings (paths/URLs)

## Files to Create/Modify

- **New:** `lib/mix/tasks/haul/seed_content.ex` — the mix task
- **New:** `priv/content/site_config.yml`
- **New:** `priv/content/services/*.yml` (6 files)
- **New:** `priv/content/endorsements/*.yml`
- **New:** `priv/content/gallery/*.yml`
- **New:** `priv/content/pages/*.md`
- **New:** Test file for the mix task
- **Modify:** `mix.exs` — add yaml_elixir dep, update setup alias
- **Existing JSON files:** `gallery.json`, `endorsements.json` can remain for backward compat with Loader
