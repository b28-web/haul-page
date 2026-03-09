# T-011-02 Review: Customer Seed Content

## Summary

Added per-operator content seeding support and created customer-1 content. The seeder now accepts an optional content root directory, and the mix task supports `--operator` flag to seed a specific operator's content.

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/content/seeder.ex` | Parameterized `seed!/2` with optional `content_root` arg; refactored helpers to thread root |
| `lib/mix/tasks/haul/seed_content.ex` | Added `--operator` flag, company find-or-create, operator content root resolution |
| `test/haul/content/seeder_test.exs` | Added 2 tests for operator-specific seeding (create + idempotency) |

## Files Created

| File | Purpose |
|------|---------|
| `priv/content/operators/customer-1/site_config.yml` | Rapid Haul Junk Removal — Austin, TX |
| `priv/content/operators/customer-1/services/*.yml` (4) | Junk removal, furniture, appliances, yard waste |
| `priv/content/operators/customer-1/endorsements/*.yml` (3) | Maria G., Dave T., Linda W. |
| `priv/content/operators/customer-1/gallery/*.yml` (3) | Placeholder gallery entries (SVG URLs) |
| `priv/content/operators/customer-1/pages/about.md` | About Rapid Haul page |
| `priv/content/operators/customer-1/pages/faq.md` | FAQ with Austin-specific content |

## Acceptance Criteria Check

| Criterion | Status |
|-----------|--------|
| `priv/content/operators/customer-1/` with site_config, services, endorsements, gallery | ✓ |
| `mix haul.seed_content --operator customer-1` loads this data | ✓ |
| Landing/scan page render with customer branding | ✓ (content seeded to DB; pages render from DB already) |
| Seed is idempotent | ✓ (tested) |

## Test Coverage

- **6 seeder tests** (4 existing + 2 new), all passing
- **208 total tests**, 0 failures — no regressions
- New tests verify: correct counts (4 services, 3 endorsements, 3 gallery, 2 pages), correct business name/phone, idempotency

## Open Concerns

1. **Gallery placeholder URLs** — Gallery items reference SVG URLs like `/images/gallery/customer-1-before-1.svg` that don't exist as actual files. The AC says "photos to be replaced with real ones" — this is expected.
2. **Customer-1 identity** — Content uses "Rapid Haul Junk Removal" as a fictional but realistic Austin, TX operator. If a real customer-1 business exists, content should be updated with their actual details.
3. **No pages/ directory fallback** — If an operator directory is missing a subdirectory (e.g., no `pages/`), the seeder returns empty list for that type. This is correct behavior but worth noting.
