# T-013-04 Gallery Manager — Structure

## Files Created

### `lib/haul_web/live/app/gallery_live.ex`
- Main LiveView for gallery management at `/app/content/gallery`
- **Mount:** resolve tenant, load all gallery items (sorted by sort_order), set up two upload channels (`:before_image`, `:after_image`)
- **Assigns:** `:items`, `:tenant`, `:page_title`, `:show_modal`, `:editing_item`, `:ash_form`
- **Events:**
  - `"add"` — open modal with create form + upload zones
  - `"edit"` — open modal with update form (metadata only)
  - `"validate"` — AshPhoenix.Form.validate
  - `"save"` — upload files (if new), submit form, reload items, close modal
  - `"delete"` — delete storage files + destroy record, reload items
  - `"move-up"` / `"move-down"` — swap sort_order with adjacent item
  - `"toggle-active"` — quick toggle active/inactive
  - `"cancel-upload"` — cancel pending upload entry
  - `"close-modal"` — close modal, reset form
- **Render:** Grid of gallery items + modal for add/edit

### `test/haul_web/live/app/gallery_live_test.exs`
- LiveView integration tests
- Setup: `create_authenticated_context`, log_in, provision tenant
- Tests: mount renders, add item with uploads, edit metadata, delete with confirmation, reorder, toggle active

## Files Modified

### `lib/haul_web/router.ex`
- Add `live "/content/gallery", App.GalleryLive` inside `:authenticated` live_session

### `lib/haul/content/gallery_item.ex`
- Add `:reorder` update action accepting only `:sort_order`
- This keeps `:edit` focused on content metadata and gives reorder its own action

### `lib/haul_web/content_helpers.ex`
- Sort gallery items by `sort_order` in `load_gallery_items/1`

## Module Boundaries

- **GalleryLive** — owns upload handling, storage interaction, modal state
- **GalleryItem resource** — owns data validation, persistence
- **Storage** — file I/O (no changes needed)
- **ContentHelpers** — public page data loading (minimal sort fix)

## Component Structure (within GalleryLive render)

```
render/1
├── Header (title + "Add Item" button)
├── Empty state (when no items)
├── Grid of item cards
│   └── Item card
│       ├── Before/after thumbnail pair
│       ├── Caption + status badges (featured, inactive)
│       ├── Action buttons (edit, move up/down, toggle active, delete)
│       └── Delete confirmation (JS.toggle)
└── Modal (when show_modal == true)
    ├── Upload zones (before + after) — only for new items
    ├── Metadata form (caption, alt_text, featured checkbox)
    └── Save/Cancel buttons
```
