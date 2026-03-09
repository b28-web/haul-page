# T-013-04 Gallery Manager — Plan

## Step 1: Add `:reorder` action to GalleryItem resource

- Add `update :reorder do accept [:sort_order] end` to gallery_item.ex
- Verify existing tests still pass

## Step 2: Fix sorting in ContentHelpers

- Add `|> Enum.sort_by(& &1.sort_order)` to `load_gallery_items/1`
- This ensures scan page displays items in correct order

## Step 3: Add route

- Add `live "/content/gallery", App.GalleryLive` to authenticated live_session in router.ex

## Step 4: Build GalleryLive — mount + data loading

- Create `lib/haul_web/live/app/gallery_live.ex`
- Mount: resolve tenant, load items sorted by sort_order, set page_title
- Set up upload channels for before/after images (5MB max, accept jpg/png/webp)
- Render: header + empty state + placeholder grid

## Step 5: Build grid view with item cards

- Render sorted items in responsive grid (2-3 columns)
- Each card: before/after thumbnails, caption, badges, action buttons
- Move up/down buttons, edit button, toggle active, delete with confirmation

## Step 6: Build modal for add/edit

- Modal component with AshPhoenix.Form
- Add mode: two upload zones (before + after) + metadata fields (caption, alt_text, featured)
- Edit mode: show current images (non-editable) + metadata fields
- Validate on change, submit on save

## Step 7: Implement event handlers

- `save` (add): consume uploads → Storage.put_object → AshPhoenix.Form.submit with image URLs
- `save` (edit): AshPhoenix.Form.submit (metadata only)
- `delete`: Storage.delete_object for both URLs → Ash.destroy
- `move-up`/`move-down`: swap sort_order values between adjacent items
- `toggle-active`: quick update via Ash changeset

## Step 8: Write tests

- Mount renders page title and empty state
- Creating item with valid uploads
- Editing item metadata
- Deleting item
- Reorder (move up/down)
- Toggle active status
- Validation errors shown

## Testing Strategy

- **Integration tests** via `Phoenix.LiveViewTest` — mount, interact, assert DOM changes
- **Setup:** `create_authenticated_context` + `log_in_user` from ConnCase
- **Teardown:** `cleanup_tenants` in `on_exit`
- **Uploads:** Use `file_input` + `render_upload` from LiveViewTest
- **No unit tests for GalleryLive** — LiveView tests are inherently integration tests

## Verification

- `mix test` passes (all existing + new tests)
- `mix format` clean
- Gallery page accessible at `/app/content/gallery` when logged in
- Items appear on scan page in correct order after creation
