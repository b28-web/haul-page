# T-013-04 Gallery Manager — Design

## Decision 1: Image Processing (Resize/Optimize)

**Options:**
1. Add `image` (libvips NIF) — powerful but heavy native dep
2. Add `mogrify` — requires ImageMagick system install
3. Skip resize/optimize for now — accept images as-is, add later

**Decision: Option 3 — skip for now.** The ticket says "resize/optimize on upload" but adding an image processing dependency is out of scope for this CRUD ticket. Images are stored as-uploaded. File size is capped at 5MB. Can add processing in a follow-up ticket. This matches the project's "no over-engineering" principle.

## Decision 2: Drag-to-Reorder Implementation

**Options:**
1. SortableJS via JS hook — proven library, works with LiveView via `phx-hook`
2. HTML5 drag-and-drop API directly — complex, poor mobile support
3. Up/down arrow buttons — no JS needed, simple but clunky UX

**Decision: Option 3 — up/down buttons.** SortableJS would require adding an npm dependency or vendoring, which conflicts with the project convention of "no node_modules." Up/down buttons work everywhere, are accessible, and integrate cleanly with LiveView events. Each click sends a `reorder` event that swaps `sort_order` values. Can upgrade to drag-and-drop later.

## Decision 3: Upload UX for Before/After Pairs

**Options:**
1. Single form with two upload zones (before + after) — clear pairing
2. Upload all images, then assign before/after labels — flexible but confusing
3. Upload one at a time with label selector — simplest

**Decision: Option 1 — two separate upload zones.** Each gallery item is a before/after pair. The upload form has two clearly labeled drop zones. This matches the data model (required before + after URLs) and is the most intuitive UX.

## Decision 4: Page Structure

**Options:**
1. Single page with grid + inline editing — compact
2. Grid page + modal for add/edit — common pattern
3. Grid page + slide-over panel — modern but complex

**Decision: Option 2 — grid with modal.** Grid shows thumbnails sorted by `sort_order`. "Add" button opens a modal with upload zones + metadata fields. Clicking an item opens the same modal for editing (metadata only, images locked). Delete has a confirmation. This follows standard admin CRUD patterns and keeps the code simple.

## Decision 5: Storage Cleanup on Delete

When a GalleryItem is destroyed, the stored image files should be deleted too. This will be handled in the LiveView's delete handler — call `Storage.delete_object` for both URLs before destroying the Ash resource. If storage deletion fails, still destroy the record (orphan files are acceptable; missing records with dangling URLs are not).

## Decision 6: Sort Order in Content Helpers

`ContentHelpers.load_gallery_items/1` currently doesn't sort. Will add `Enum.sort_by(&(&1.sort_order))` to ensure scan page respects ordering. Minimal change, high impact.

## Architecture Summary

- **New file:** `lib/haul_web/live/app/gallery_live.ex` — main LiveView
- **Modified:** Router (add route), ContentHelpers (add sorting), GalleryItem (add `:reorder` action)
- **No new JS dependencies** — pure LiveView + upload components
- **Pattern:** Follow SiteConfigLive for auth/tenant setup, BookingLive for upload handling
