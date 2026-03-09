---
id: T-010-02
story: S-010
title: gallery-placeholders
type: bug
status: done
priority: medium
phase: done
depends_on: []
---

## Context

`/scan` gallery section shows broken images. The scan page references images at `/images/gallery/before-{n}.jpg` and `/images/gallery/after-{n}.jpg` (n = 1, 2, 3) but no files exist at `priv/static/images/gallery/`.

The gallery data model (T-005-02) and scan page layout (T-005-01) are both marked done, and the browser QA (T-005-04) passed — but actual image files were never placed. The content seed task (T-006-03) will seed DB records but won't create image files either.

## Fix

1. Generate or source 6 placeholder images for the gallery (3 before/after pairs). Options:
   - Simple solid-color SVGs with "Before" / "After" text overlay (lightest, no binary bloat)
   - Small JPEG placeholders (keep under 50KB each)
2. Place them at `priv/static/images/gallery/{before,after}-{1,2,3}.jpg` (or `.svg` if the template img tags can accept that — check the `src` attributes)
3. Verify `/scan` renders all gallery items with visible images, no console 404s
4. If the image paths are hardcoded in the gallery data JSON, ensure paths match

## Acceptance Criteria

- All 6 gallery images load on `/scan` without 404s
- Images are visible (not zero-size or transparent)
- No console errors related to missing resources
