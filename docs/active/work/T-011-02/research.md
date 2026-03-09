# T-011-02 Research: Customer Seed Content

## Current Content Seeding Architecture

### Seed Task (`lib/mix/tasks/haul/seed_content.ex`)
- Entry point: `mix haul.seed_content` (no arguments)
- Reads all companies from DB, derives tenant schema for each
- Calls `Haul.Content.Seeder.seed!(tenant)` per company
- Returns summary with counts per resource type

### Seeder Module (`lib/haul/content/seeder.ex`)
- Reads YAML/markdown files from hardcoded `priv/content/` path
- Helper: `content_path/1` → `:code.priv_dir(:haul) |> Path.join("content/#{relative}")`
- Helper: `glob_yaml/1` → globs `*.yml` in subdir
- All paths are relative to the single `priv/content/` root
- Idempotent via natural-key matching (title, customer_name, before_image_url, slug)
- `atomize/1` uses `String.to_existing_atom/1` — atoms must pre-exist

### Content Directory Structure
```
priv/content/
├── site_config.yml          # Singleton, hardcoded "Junk & Handy" demo data
├── services/                # 6 YAML files (junk-removal, furniture-pickup, etc.)
├── gallery/                 # 3 YAML files with SVG placeholder URLs
├── endorsements/            # 4 YAML files (Jane D., Mike R., Sarah K., Tom B.)
├── pages/                   # 2 markdown files (about.md, faq.md)
├── endorsements.json        # Legacy bridge loader (unused by seeder)
└── gallery.json             # Legacy bridge loader (unused by seeder)
```

### Ash Content Resources
| Resource | Required Fields | Natural Key | Create Action | Update Action |
|----------|----------------|-------------|---------------|---------------|
| SiteConfig | business_name, phone | singleton (read all) | :create_default | :edit |
| Service | title, description, icon | title | :add | :edit |
| GalleryItem | before_image_url, after_image_url | before_image_url | :add | :edit |
| Endorsement | customer_name, quote_text | customer_name | :add | :edit |
| Page | slug, title, body | slug | :draft | :edit |

### Operator Config (`config/config.exs`)
- Default operator: slug "junk-and-handy", name "Junk & Handy"
- Runtime overrides via env vars (OPERATOR_NAME, OPERATOR_PHONE, etc.)
- Company created in `priv/repo/seeds.exs` using operator config slug

### Company/Tenant Model
- `Haul.Accounts.Company` — has `name` and `slug`
- Tenant schema: `tenant_#{company.slug}` (via ProvisionTenant change)
- Each company gets its own Postgres schema with isolated content

### Existing Tests (`test/haul/content/seeder_test.exs`)
- Tests `seed!/1` with a fresh company/tenant
- Asserts exact counts: 6 services, 3 gallery, 4 endorsements, 2 pages
- Tests idempotency (second run returns :updated for all)
- Tests `parse_frontmatter!/1` separately

## Gap Analysis

### What the ticket requires
1. Per-operator content directory: `priv/content/operators/customer-1/`
2. CLI flag: `mix haul.seed_content --operator customer-1`
3. Customer-1-specific content (real business info, not demo data)
4. Landing page and scan page render with customer's branding

### What needs to change
1. **Seeder module** — needs a `content_root` parameter instead of hardcoded `priv/content/`
2. **Seed task** — needs `--operator` argument parsing, map operator name to content dir and company
3. **Content files** — new `priv/content/operators/customer-1/` tree with real data
4. **Existing tests** — currently assert against hardcoded demo data; need to remain valid
5. **Default content** — `priv/content/` should remain the fallback (existing behavior preserved)

### Constraints
- The existing `priv/content/` directory and its data must remain intact (default/demo content)
- Existing seeder test assertions (6 services, 3 gallery, etc.) must keep passing
- `String.to_existing_atom/1` means YAML keys must match existing atom names
- Gallery items use SVG placeholder URLs — customer-1 gallery should too (photos to be replaced later per AC)
- No changes to Ash resource definitions needed — same schema, different data
