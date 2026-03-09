# T-011-02 Design: Customer Seed Content

## Problem
The seeder reads from a single hardcoded `priv/content/` directory. We need per-operator content directories and a CLI flag to seed a specific operator.

## Approach: Parameterized Content Root

### Option A: Content root as parameter to Seeder
Pass the content directory path into `seed!/2` as a second argument. The seed task resolves `--operator customer-1` → `priv/content/operators/customer-1/` and passes it through.

**Pros:** Minimal change, clear data flow, easy to test.
**Cons:** None significant.

### Option B: Operator-aware Seeder with config lookup
Seeder internally resolves operator name to directory via config or convention.

**Pros:** Encapsulates resolution logic.
**Cons:** Couples seeder to operator naming conventions unnecessarily.

### Decision: Option A

The seeder should be a pure function of (tenant, content_root). The mix task handles argument parsing and resolution. This keeps the seeder testable and the task simple.

## Design Details

### Seeder Changes
- `seed!(tenant)` → `seed!(tenant, content_root \\ default_content_root())`
- `content_path/1` becomes `content_path/2` taking root as first arg
- `glob_yaml/1` and `glob_files/2` take root as first arg
- All private functions thread the root through
- Default root = `priv/content/` (backward compatible)

### Mix Task Changes
- Parse `--operator` option from args via `OptionParser`
- If `--operator customer-1` given:
  - Content root = `priv/content/operators/customer-1/`
  - Find or create company with slug "customer-1"
  - Seed only that company's tenant with the operator-specific content
- If no `--operator` given: existing behavior (seed all companies from default content)

### Company Resolution
When `--operator customer-1` is specified:
1. Look up Company by slug "customer-1"
2. If not found, create it using site_config.yml's business_name
3. Derive tenant schema and seed

This matches the existing seeds.exs pattern where Company is created with a slug.

### Content Directory Layout
```
priv/content/operators/customer-1/
├── site_config.yml
├── services/
│   ├── junk-removal.yml
│   ├── furniture-pickup.yml
│   ├── appliance-hauling.yml
│   └── yard-waste.yml
├── endorsements/
│   ├── maria-g.yml
│   ├── dave-t.yml
│   └── linda-w.yml
├── gallery/
│   ├── garage-cleanout.yml
│   ├── backyard-debris.yml
│   └── patio-furniture.yml
└── pages/
    ├── about.md
    └── faq.md
```

### Customer #1 Content
Since the ticket says "real business information" but doesn't specify which business, and the default operator is "Junk & Handy", customer-1 will be a distinct operator identity. The content should be realistic but fictional (a representative junk removal operator), since we don't have actual customer data to embed. The key difference from default content: unique business name, phone, service area, tailored descriptions, and different testimonial names.

### Test Strategy
- Existing seeder test continues to pass (uses default content root)
- New test: seed with operator-specific content root, verify different data
- Test `--operator` flag in mix task (or just test seeder with custom root)
