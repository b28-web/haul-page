# T-005-02 Design: Gallery Data

## Options evaluated

### Option A: Add to operator config (config.exs)

Add `gallery_items` and `endorsements` keys to the existing `config :haul, :operator` block. ScanLive reads from `Application.get_env(:haul, :operator)`.

Pros: Matches existing pattern exactly. Zero new modules.
Cons: Mixes content data with operator identity. Services list is already pushing the limits of config — adding photo URLs and review text makes it unwieldy. Env var overrides don't work for nested lists of maps. Doesn't match the future `priv/content/` seed directory structure from content-system.md.

### Option B: JSON files in priv/content/

Create `priv/content/gallery.json` and `priv/content/endorsements.json`. A thin loader module reads and caches them at startup. ScanLive calls the loader.

Pros: Clean separation of content from config. JSON parsing via Jason (already a dep). File structure aligns with content-system.md seed directory layout. Easy to inspect/edit. Data shape can match the future Ash resource exactly. No new deps needed.
Cons: New module (loader). Slight startup cost (negligible — tiny files).

### Option C: Ash resources immediately

Skip the intermediate step. Create `Haul.Content` domain with `GalleryItem` and `Endorsement` resources, migrations, seeds.

Pros: Future-proof, no throwaway code.
Cons: Requires Haul.Content domain (not created yet, part of T-006-xx which is blocked on T-004-01). Would need migrations, seed tasks, and the content domain setup — scope creep beyond this ticket. The ticket AC explicitly says "Initial implementation: loaded from runtime config or a JSON/YAML file in priv/."

## Decision: Option B — JSON files in priv/content/

Rationale:
1. Ticket AC explicitly calls for "runtime config or JSON/YAML file in priv/" — JSON files are the cleanest fit
2. Separates content from operator identity config (which is already long)
3. Aligns with the `priv/content/` seed directory structure from content-system.md
4. Jason is already a dep; no YAML parser needed
5. Data shape will use the ticket AC field names (before_photo_url, customer_name, etc.) which map cleanly to the future Ash resource attributes
6. When Ash resources land, the JSON files become seed data and the loader gets replaced with `Ash.read!()` calls — minimal throwaway code

## Data structure

### Gallery item (JSON shape)
```json
{
  "before_photo_url": "/images/gallery/before-1.jpg",
  "after_photo_url": "/images/gallery/after-1.jpg",
  "caption": "Full garage cleanout — hauled in one trip"
}
```

### Endorsement (JSON shape)
```json
{
  "customer_name": "Jane D.",
  "quote_text": "Called in the morning, they were here by lunch.",
  "star_rating": 5,
  "date": "2025-11-15"
}
```

Both are JSON arrays. Fields use the ticket AC names. `star_rating` and `date` are optional (nullable). `caption` is optional.

## Loader design

`Haul.Content.Loader` — reads JSON files from `priv/content/` at application start, caches in persistent_term. Provides `gallery_items/0` and `endorsements/0` functions that return lists of maps with atom keys.

Using persistent_term because:
- Content is static (changes only on redeploy)
- No per-process overhead (unlike Application.get_env for large data)
- Simple get/put API
- Will be removed entirely when Ash resources replace it

## Template changes

ScanLive template field references update:
- `item.before_url` → `item.before_photo_url`
- `item.after_url` → `item.after_photo_url`
- `endorsement.name` → `endorsement.customer_name`
- `endorsement.quote` → `endorsement.quote_text`
- `endorsement.stars` → `endorsement.star_rating`

Tests update to use loader data instead of hardcoded names.
