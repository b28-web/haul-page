# T-014-02 Design: Default Content Pack

## Decision: Create `priv/content/defaults/` as a standalone pack

### Options considered

**A. Rename `priv/content/` to `priv/content/defaults/`**
- Breaks existing `mix haul.seed_content` (which uses `priv/content/` as default root)
- Breaks operator-specific packs under `priv/content/operators/`
- Too disruptive

**B. Create `priv/content/defaults/` as new directory, update Onboarding to use it**
- Clean separation: `priv/content/` remains the dev/demo pack, `priv/content/defaults/` is the generic new-operator pack
- Onboarding changes one line: `Seeder.seed!(tenant, defaults_content_root())`
- Operator-specific packs still work at `priv/content/operators/{slug}/`
- Non-breaking

**C. Just modify existing `priv/content/` to be more generic**
- Loses the "Junk & Handy" branded dev content
- Mixes concerns

**Decision: Option B.** New `priv/content/defaults/` directory. Onboarding seeds from there. Existing content untouched.

## Service Names

Ticket specifies: Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help.

Current `priv/content/` has: Junk Removal, Furniture Pickup, Appliance Hauling, Yard Waste, Construction Debris, Estate Cleanout.

The ticket's list is more general-purpose — a hauler who also does handyman work. This makes sense as defaults that cover the broadest operator profiles. Operators customize from admin UI.

## Gallery: 4 items (ticket says 4, currently 3 SVGs exist)

Create a 4th SVG pair (before-4.svg, after-4.svg) matching the existing minimalist SVG style. All 4 gallery YAML files reference these stock SVGs.

## Endorsements: 3 samples

Ticket says "clearly marked as samples in admin UI." Simplest approach: include "(Sample)" in the customer_name field. This is visible in admin CRUD lists and clearly signals "replace me." No model changes needed. Operator edits name when replacing with real testimonial.

Alternative: add a `sample` boolean attribute. Rejected — over-engineering for a text marker.

## SiteConfig: Placeholder values

Use generic placeholder text that reads well but is obviously template content. Business name: "Your Business Name". Operator overrides phone/email/area during onboarding anyway.

## Pages: Generic about + FAQ

Write generic versions without brand references. Use "your business" / "our team" language that works for any hauler.

## Onboarding integration

Change `seed_content/1` in `Haul.Onboarding` to pass `defaults_content_root()` to the seeder. Add a private function that resolves `priv/content/defaults/`.

## Test strategy

- Unit test: verify default content files parse correctly
- Integration: existing onboarding tests will exercise the new defaults path
- Add a test that verifies all expected default files exist and are valid YAML/MD
