# T-013-04 Gallery Manager — Review

## Summary

Built the `/app/content/gallery` admin LiveView for managing before/after photo galleries. Operators can upload image pairs, add captions/alt text, reorder items, toggle visibility, and delete with confirmation. Changes appear on the scan page immediately.

## Files Created

| File | Purpose |
|------|---------|
| `lib/haul_web/live/app/gallery_live.ex` | Main gallery manager LiveView (~490 lines) |
| `test/haul_web/live/app/gallery_live_test.exs` | LiveView integration tests (11 tests) |
| `test/support/fixtures/test_image.jpg` | Minimal JPEG for upload tests |
| `priv/repo/tenant_migrations/20260309030223_fix_gallery_versions_cascade.exs` | Drop FK constraint on versions table |

## Files Modified

| File | Change |
|------|--------|
| `lib/haul/content/gallery_item.ex` | Added `:reorder` update action (accepts only `:sort_order`) |
| `lib/haul_web/router.ex` | Added `/content/gallery` route to authenticated live_session |
| `lib/haul_web/content_helpers.ex` | Added `Enum.sort_by(& &1.sort_order)` to `load_gallery_items/1` |

## Test Coverage

- **11 new tests** covering:
  - Mount with empty state
  - Mount with existing items
  - Add modal opens
  - Create item with file uploads
  - Edit modal shows existing data
  - Update item metadata
  - Delete item
  - Move item up
  - Move item down
  - Toggle active/inactive
  - Close modal

- **Full suite: 280 tests, 0 failures**

## Acceptance Criteria Status

| Criterion | Status |
|-----------|--------|
| `/app/content/gallery` LiveView | Done |
| Grid view with thumbnails | Done |
| Drag-to-reorder | Done (up/down buttons — no JS dependency needed) |
| Upload JPEG, PNG, WebP | Done |
| Resize/optimize on upload | Deferred (no image processing dep added) |
| Edit caption, before/after label, alt text | Done |
| Delete with confirmation | Done |
| Images stored with tenant-scoped keys | Done (via `Storage.upload_key`) |
| Changes reflect on scan page immediately | Done (ContentHelpers sorts by sort_order) |
| Max file size 5MB | Done |

## Open Concerns

1. **Image resize/optimize deferred** — The ticket specifies "resize/optimize on upload" but no image processing library exists in the project. Adding one (e.g., `image` or `mogrify`) is a separate concern. Images are stored as-uploaded with 5MB cap. This should be a follow-up ticket.

2. **PaperTrail FK migration** — Had to drop the FK constraint on `gallery_items_versions.version_source_id` because PaperTrail creates a version record during `Ash.destroy!` but the FK check fails within the same transaction. This is a known pattern issue with PaperTrail + Ash destroy. The same issue may affect other PaperTrail-tracked resources (Service, Endorsement, SiteConfig) if they ever support delete. The version records still store the source_id as a UUID, just without referential integrity.

3. **Drag-to-reorder vs up/down buttons** — Implemented up/down arrow buttons instead of SortableJS drag-and-drop to avoid adding a JS dependency (project convention: no node_modules). Works well for small galleries but may be tedious for large ones. Could upgrade to drag-and-drop later if needed.

4. **Storage cleanup on delete** — `delete_storage_files` extracts the key from the URL and calls `Storage.delete_object`. This works for both local (`/uploads/...`) and S3 (`https://...`) URLs. If storage deletion fails, the record is still destroyed (orphan files acceptable).

5. **No image replacement** — The `:edit` action doesn't accept image URL changes. To change images, the operator must delete and re-create the gallery item. This matches the current resource design.
