---
id: T-013-04
story: S-013
title: gallery-manager
type: task
status: open
priority: medium
phase: ready
depends_on: [T-013-01, T-005-02]
---

## Context

Let the operator manage their before/after photo gallery — upload images, add captions, reorder, delete. Gallery appears on the scan page.

## Acceptance Criteria

- `/app/content/gallery` LiveView
- Grid view: thumbnails of all gallery items, drag-to-reorder
- Upload: accept images (JPEG, PNG, WebP), resize/optimize on upload
- Edit: caption, before/after label, alt text
- Delete with confirmation
- Images stored in Tigris (S3-compatible) with tenant-scoped keys
- Changes reflect on scan page gallery immediately
- Max file size: 5MB per image
