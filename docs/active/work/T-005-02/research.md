# T-005-02 Research: Gallery Data

## Current state

### Hardcoded data in ScanLive

`lib/haul_web/live/scan_live.ex` has two module attributes with hardcoded data:

```elixir
@gallery_items [
  %{before_url: "/images/gallery/before-1.jpg", after_url: "/images/gallery/after-1.jpg", caption: "..."},
  # 3 items total
]

@endorsements [
  %{name: "Jane D.", quote: "...", stars: 5},
  # 4 items total
]
```

These are assigned to the socket in `mount/3` and rendered in the template. No external data source.

### Existing operator config pattern

`config/config.exs` defines `config :haul, :operator` with business identity + services list (maps with title/description/icon). `config/runtime.exs` merges env var overrides for scalar fields only (not services list). Landing page controller reads via `Application.get_env(:haul, :operator)`.

Pattern: compile-time defaults in config, runtime env var overrides for scalars, no file-based loading.

### Content system design (future target)

`docs/knowledge/content-system.md` defines the target Ash resources:
- `Haul.Content.GalleryItem` — uuid PK, before_image_url, after_image_url, caption, alt_text, sort_order, featured, active
- `Haul.Content.Endorsement` — uuid PK, customer_name, quote_text, star_rating (1-5), source (enum), date, featured, active, optional belongs_to :job

Seed workflow: YAML files in `priv/content/gallery/` and `priv/content/endorsements/` → seed task upserts into DB.

### Image serving

No gallery images exist yet. `priv/static/images/` has only `logo.svg`. ScanLive references `/images/gallery/before-1.jpg` etc. with graceful fallback (onerror hides img, shows icon placeholder).

Images served from `priv/static/` via Phoenix static plug. Future: Tigris S3-compatible storage.

### Test coverage

`test/haul_web/live/scan_live_test.exs` — 8 tests. Checks gallery section renders "Our Work" heading + Before/After labels, endorsement section renders all 4 customer names, star ratings present. Tests assert hardcoded names ("Jane D.", "Mike R.", etc.).

### Data shape comparison

| ScanLive (current) | Ticket AC | Ash resource (future) |
|---|---|---|
| before_url | before_photo_url | before_image_url |
| after_url | after_photo_url | after_image_url |
| caption | caption | caption |
| — | — | alt_text, sort_order, featured, active |

| ScanLive (current) | Ticket AC | Ash resource (future) |
|---|---|---|
| name | customer_name | customer_name |
| quote | quote_text | quote_text |
| stars | star_rating | star_rating |
| — | date | date |
| — | — | source, featured, active |

### Dependencies

T-005-01 (scan-page-layout) is done. ScanLive exists and works. No other dependencies.

### Constraints

- No Ash Content domain yet (T-006-xx, blocked on T-004-01)
- No database migrations for content resources
- No YAML parser in deps (would need yaml_elixir)
- JSON parsing available via Jason (already a dep)
- Must not break existing 8 scan page tests
