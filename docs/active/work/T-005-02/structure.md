# T-005-02 Structure: Gallery Data

## Files created

### priv/content/gallery.json
JSON array of gallery items. Each item: `before_photo_url` (string, required), `after_photo_url` (string, required), `caption` (string, optional). 3 items matching current hardcoded data with renamed fields.

### priv/content/endorsements.json
JSON array of endorsements. Each item: `customer_name` (string, required), `quote_text` (string, required), `star_rating` (integer 1-5, optional), `date` (string ISO 8601, optional). 4 items matching current hardcoded data with renamed fields + date added.

### lib/haul/content/loader.ex
Module: `Haul.Content.Loader`

Public API:
- `load!/0` — reads JSON files from `priv/content/`, stores in persistent_term. Called at app startup.
- `gallery_items/0` — returns `[%{before_photo_url: String.t(), after_photo_url: String.t(), caption: String.t() | nil}]`
- `endorsements/0` — returns `[%{customer_name: String.t(), quote_text: String.t(), star_rating: integer() | nil, date: String.t() | nil}]`

Internal:
- `read_json!/1` — reads and decodes a JSON file from priv/content/, converts keys to atoms
- persistent_term keys: `{Haul.Content.Loader, :gallery_items}`, `{Haul.Content.Loader, :endorsements}`

## Files modified

### lib/haul/application.ex
Add `Haul.Content.Loader.load!()` call in `start/2` after repo setup, before endpoint. This ensures content is loaded before any LiveView mounts.

### lib/haul_web/live/scan_live.ex
- Remove `@gallery_items` and `@endorsements` module attributes
- In `mount/3`: call `Haul.Content.Loader.gallery_items()` and `Haul.Content.Loader.endorsements()` instead
- In `render/1` template: update field references:
  - `item.before_url` → `item.before_photo_url`
  - `item.after_url` → `item.after_photo_url`
  - `endorsement.name` → `endorsement.customer_name`
  - `endorsement.quote` → `endorsement.quote_text`
  - `endorsement.stars` → `endorsement.star_rating`

### test/haul_web/live/scan_live_test.exs
- Update endorsement name assertions to read from `Haul.Content.Loader.endorsements()` instead of hardcoding "Jane D.", "Mike R.", etc.
- Add test that gallery items from loader appear in rendered HTML
- Add test for endorsement with optional date field

### test/haul/content/loader_test.exs (new)
- Test `load!/0` populates persistent_term
- Test `gallery_items/0` returns list of maps with correct keys
- Test `endorsements/0` returns list of maps with correct keys
- Test data shapes match expected types (star_rating is integer, etc.)

## Module boundaries

```
Haul.Content.Loader (new)
  ├── reads priv/content/*.json
  ├── caches in persistent_term
  └── provides typed accessor functions

HaulWeb.ScanLive (modified)
  └── calls Loader instead of using module attributes
```

The Loader lives in `lib/haul/content/` anticipating the future `Haul.Content` Ash domain. When Ash resources land, the Loader module gets deleted and callers switch to `Ash.read!()`.

## Files not modified

- `config/config.exs` — gallery/endorsement data stays out of operator config
- `config/runtime.exs` — no env var overrides for content (managed via JSON files)
- `lib/haul_web/router.ex` — no route changes
- Landing page (PageController) — not affected
