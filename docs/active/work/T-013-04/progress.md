# T-013-04 Gallery Manager — Progress

## Completed Steps

### Step 1: Add `:reorder` action to GalleryItem resource
- Added `update :reorder do accept [:sort_order] end` to `lib/haul/content/gallery_item.ex`
- Keeps `:edit` focused on metadata, `:reorder` for sort_order changes

### Step 2: Fix sorting in ContentHelpers
- Added `|> Enum.sort_by(& &1.sort_order)` to `load_gallery_items/1`
- Scan page now displays items in correct sort order

### Step 3: Add route
- Added `live "/content/gallery", App.GalleryLive` to authenticated live_session in router.ex

### Step 4-7: Build GalleryLive (all in one file)
- Created `lib/haul_web/live/app/gallery_live.ex` with full CRUD functionality
- Mount: resolves tenant, loads items sorted by sort_order, configures uploads
- Grid view: responsive 1-3 column grid with before/after thumbnails, captions, badges
- Modal: add mode (two upload zones + metadata) and edit mode (metadata only)
- Upload: LiveView file uploads for before/after images (5MB max, JPEG/PNG/WebP)
- Reorder: up/down buttons swap sort_order values between adjacent items
- Toggle active: quick eye/eye-slash button to toggle visibility
- Delete: with data-confirm dialog, cleans up storage files, removes PaperTrail versions

### Step 8: Write tests
- Created `test/haul_web/live/app/gallery_live_test.exs` with 11 tests
- Created `test/support/fixtures/test_image.jpg` for upload tests

### Migration: Fix PaperTrail FK constraint
- Created `priv/repo/tenant_migrations/20260309030223_fix_gallery_versions_cascade.exs`
- Drops FK constraint on `gallery_items_versions.version_source_id`
- Required because PaperTrail creates a version record during destroy, but FK check fails within the same transaction

## Deviations from Plan

1. **PaperTrail FK issue** — Discovered that destroying a GalleryItem fails because PaperTrail tries to insert a version record pointing to the deleted record's ID. The FK constraint prevents this within the same transaction. Fixed by dropping the FK constraint (version_source_id is kept as plain UUID). This required a new tenant migration.

2. **No image resize/optimize** — As designed, skipped image processing. Files stored as-uploaded with 5MB cap.

## Test Results

- 280 tests, 0 failures
- 11 new gallery tests all passing
- All existing tests unaffected
