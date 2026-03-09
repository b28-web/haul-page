# T-014-02 Structure: Default Content Pack

## New files

### Content pack: `priv/content/defaults/`
```
priv/content/defaults/
├── site_config.yml
├── services/
│   ├── junk-removal.yml
│   ├── cleanouts.yml
│   ├── yard-waste.yml
│   ├── repairs.yml
│   ├── assembly.yml
│   └── moving-help.yml
├── endorsements/
│   ├── sample-alex.yml
│   ├── sample-maria.yml
│   └── sample-chris.yml
├── gallery/
│   ├── kitchen-cleanup.yml
│   ├── garage-cleanout.yml
│   ├── yard-debris.yml
│   └── office-clearout.yml
└── pages/
    ├── about.md
    └── faq.md
```

### Gallery SVG: `priv/static/images/gallery/before-4.svg`, `after-4.svg`
Minimal SVG placeholders matching existing style (simple geometric shapes with labels).

## Modified files

### `lib/haul/onboarding.ex`
- `seed_content/1`: change from `Seeder.seed!(tenant)` to `Seeder.seed!(tenant, defaults_content_root())`
- Add `defp defaults_content_root`: resolves `priv/content/defaults/`

### `test/haul/onboarding_test.exs`
- Update assertions to match new default content counts (6 services, 4 gallery, 3 endorsements)
- Add test verifying default content file integrity

## New test file

### `test/haul/content/defaults_test.exs`
- Verify all expected files exist under `priv/content/defaults/`
- Verify YAML files parse without errors
- Verify markdown pages have valid frontmatter
- Verify service count = 6, endorsement count = 3, gallery count = 4

## Unchanged
- `lib/haul/content/seeder.ex` — already accepts `content_root` parameter
- `lib/mix/tasks/haul/seed_content.ex` — continues using `priv/content/` as default for existing tenants
- `lib/mix/tasks/haul/onboard.ex` — calls `Onboarding.run/1` which handles the path internally
- All existing content under `priv/content/` — untouched
