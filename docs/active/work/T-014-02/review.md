# T-014-02 Review: Default Content Pack

## Summary

Created a professional default content pack at `priv/content/defaults/` that every new operator gets when onboarded. Updated the Onboarding module to seed from this pack instead of the dev/demo content.

## Files created

### Content pack (15 files)
- `priv/content/defaults/site_config.yml` — generic placeholder config
- `priv/content/defaults/services/` — 6 YAMLs (Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help)
- `priv/content/defaults/endorsements/` — 3 YAMLs with "(Sample)" marker in customer_name
- `priv/content/defaults/gallery/` — 4 YAMLs referencing SVG placeholders
- `priv/content/defaults/pages/about.md` — generic about page
- `priv/content/defaults/pages/faq.md` — generic FAQ with pricing table

### SVG placeholders (2 files)
- `priv/static/images/gallery/before-4.svg` — office clutter scene
- `priv/static/images/gallery/after-4.svg` — clean desk scene

### Test file (1 file)
- `test/haul/content/defaults_test.exs` — 8 tests validating pack structure and content

## Files modified

- `lib/haul/onboarding.ex` — `seed_content/1` now passes `defaults_content_root()` to seeder; added `defaults_content_root/0`
- `test/haul/onboarding_test.exs` — updated content count assertions (6 services, 4 gallery, 3 endorsements)

## Test coverage

- **8 new tests** in `defaults_test.exs`: file existence, YAML parsing, title matching, sample markers, SVG references, page frontmatter
- **13 existing tests** in `onboarding_test.exs`: updated assertions pass with new defaults
- **315 total tests, 0 failures** — no regressions

## Acceptance criteria verification

| Criterion | Status |
|---|---|
| `priv/content/defaults/` directory with site_config.yml | Done |
| 6 standard services with real descriptions | Done — Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help |
| 3 sample testimonials marked as samples | Done — "(Sample)" in customer_name |
| 4 placeholder gallery entries | Done — references 4 SVG pairs |
| Seed task loads defaults for new tenant | Done — Onboarding.seed_content uses defaults path |
| Default content is editable | Already true — Ash `:edit` actions exist on all resources |
| Content is good enough to go live | Yes — real descriptions, professional tone, no lorem ipsum |

## Design decisions

1. **Separate directory** — `priv/content/defaults/` is distinct from `priv/content/` (dev/demo content). Existing seed task and operator-specific packs unaffected.
2. **"(Sample)" marker** — endorsement customer names include "(Sample)" so operators know to replace them. No model changes needed — just edit the name.
3. **Generic language** — all text uses "we/our" without brand names, so it works for any hauling operator out of the box.

## Open concerns

- **None blocking.** The pack is complete and tested.
- **Minor:** The `priv/content/` directory (old default) is now only used by `mix haul.seed_content` for existing tenants and operator-specific packs. This is intentional — the two paths serve different purposes.
