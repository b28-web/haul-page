# T-011-02 Structure: Customer Seed Content

## Files Modified

### `lib/haul/content/seeder.ex`
- `seed!/1` gains optional second arg: `seed!(tenant, content_root \\ default_content_root())`
- All private functions (`seed_site_config`, `seed_services`, etc.) accept content_root
- `content_path/1` → uses provided root instead of hardcoded path
- `glob_yaml/1`, `glob_files/2` → thread root through
- New `default_content_root/0` → `:code.priv_dir(:haul) |> Path.join("content")`

### `lib/mix/tasks/haul/seed_content.ex`
- Add OptionParser for `--operator` switch
- When `--operator slug` provided:
  - Resolve content_root to `priv/content/operators/{slug}/`
  - Find or create Company with that slug
  - Seed only that tenant with operator-specific content
- When no flag: existing behavior (all companies, default content)

## Files Created

### Content Files: `priv/content/operators/customer-1/`
```
site_config.yml          — Customer #1 business identity
services/
  junk-removal.yml       — Core service
  furniture-pickup.yml   — Furniture removal
  appliance-hauling.yml  — Appliance disposal
  yard-waste.yml         — Yard/garden cleanup
endorsements/
  maria-g.yml            — Testimonial 1
  dave-t.yml             — Testimonial 2
  linda-w.yml            — Testimonial 3
gallery/
  garage-cleanout.yml    — Placeholder gallery entry 1
  backyard-debris.yml    — Placeholder gallery entry 2
  patio-furniture.yml    — Placeholder gallery entry 3
pages/
  about.md               — Customer-specific about page
  faq.md                 — Customer-specific FAQ
```

### Test File Updates
- `test/haul/content/seeder_test.exs` — add test for `seed!/2` with custom content root

## Module Boundaries

- **Seeder**: Pure function of (tenant, content_root). No knowledge of operator names or CLI args.
- **Mix Task**: Argument parsing, company resolution, delegates to Seeder.
- **Content files**: Static YAML/markdown, no code.

## No Changes Needed
- Ash resource definitions (SiteConfig, Service, etc.) — schema unchanged
- Content domain module — no new resources
- Landing page / scan page templates — they already render from DB content
- Config files — operator config is separate from seed content
