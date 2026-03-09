# T-014-02 Research: Default Content Pack

## Current Content System

### Content Domain Resources
Five Ash resources in `lib/haul/content/`:
- **SiteConfig** — singleton per tenant. Attrs: business_name, phone, email, tagline, service_area, address, coupon_text, meta_description, primary_color, logo_url. Actions: `:create_default`, `:edit`.
- **Service** — title (required), description (required), icon (required), sort_order, active. Matched by `title`. Actions: `:add`, `:edit`.
- **GalleryItem** — before_image_url, after_image_url (required), caption, alt_text, sort_order, featured, active. Matched by `before_image_url`. Actions: `:add`, `:edit`.
- **Endorsement** — customer_name, quote_text (required), star_rating, source (enum: google/yelp/direct/facebook), date, featured, active, sort_order. Matched by `customer_name`. Actions: `:add`, `:edit`.
- **Page** — slug (unique), title, body, body_html (computed), meta_description, published. Matched by `slug`. Actions: `:draft`, `:edit`.

### Seeder (`lib/haul/content/seeder.ex`)
- `seed!(tenant, content_root \\ priv/content/)` — idempotent, matches by natural keys
- Reads YAML from `site_config.yml`, `services/*.yml`, `gallery/*.yml`, `endorsements/*.yml`, `pages/*.md`
- Uses `YamlElixir` for YAML, custom `parse_frontmatter!` for markdown pages
- `atomize/1` converts string keys to atoms via `String.to_existing_atom/1`

### Onboarding (`lib/haul/onboarding.ex`)
- `run(%{name, phone, email, area})` orchestrates: Company → Tenant → `Seeder.seed!(tenant)` → SiteConfig update → Owner user
- Currently calls `Seeder.seed!(tenant)` with **default** content_root (`priv/content/`)
- After seeding, updates SiteConfig with operator's phone/email/area

### Current Content (`priv/content/`)
```
priv/content/
├── site_config.yml          # "Junk & Handy" branded
├── services/                # 6 services (junk-removal, furniture-pickup, appliance-hauling, yard-waste, construction-debris, estate-cleanout)
├── gallery/                 # 3 items (SVG placeholders: before-1..3, after-1..3)
├── endorsements/            # 4 testimonials (jane-d, mike-r, sarah-k, tom-b)
├── pages/                   # 2 pages (about.md, faq.md) — "Junk & Handy" branded
├── gallery.json             # Legacy (pre-Ash)
├── endorsements.json        # Legacy (pre-Ash)
└── operators/customer-1/    # Operator-specific override pack
```

### Gallery SVGs
6 SVG files at `priv/static/images/gallery/`: before-1.svg, after-1.svg, before-2.svg, after-2.svg, before-3.svg, after-3.svg. Referenced by gallery YAML as `/images/gallery/before-N.svg`.

### Test Infrastructure
- `test/haul/onboarding_test.exs` — 9 tests, async: false. Tests end-to-end onboarding, idempotency, validation. Cleans up tenant schemas on exit.
- Content seeding is tested implicitly via onboarding tests (asserts `length(result.content.services) > 0`).

## Gap Analysis

### What the ticket wants vs what exists

| Requirement | Current State |
|---|---|
| `priv/content/defaults/` directory | Does NOT exist |
| `site_config.yml` with placeholder values | Exists at `priv/content/site_config.yml` but branded "Junk & Handy" |
| 6 standard services | 6 exist but named differently (no "Repairs", "Assembly", "Moving Help") |
| 3 sample testimonials (marked as samples) | 4 exist, not marked as samples |
| 4 placeholder gallery entries | 3 exist |
| Seed task loads defaults for new tenant | Onboarding loads from `priv/content/` — needs to point to defaults |
| Content editable from admin UI | Already true (Ash `:edit` actions exist) |

### Key decisions needed
1. Do we create `priv/content/defaults/` as a new directory, or reorganize existing content?
2. How to match the 6 required services (Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help) with existing 6 (different mix)?
3. Need a 4th gallery SVG pair (before-4.svg, after-4.svg)
4. How to mark endorsements as "samples" in admin UI — attribute on the model, or just text in the quote?
5. Should Onboarding point to `priv/content/defaults/` or continue using `priv/content/`?
