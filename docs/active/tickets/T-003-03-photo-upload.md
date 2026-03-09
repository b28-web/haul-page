---
id: T-003-03
story: S-003
title: photo-upload
type: task
status: open
priority: medium
phase: ready
depends_on: [T-003-02]
---

## Context

Add photo upload to the booking form. Customers can snap photos of their junk from their phone camera. Photos stored in Fly Tigris (S3-compatible).

## Acceptance Criteria

- `input[type=file][accept="image/*"][capture=environment]` opens camera on mobile
- Multiple photos supported (up to 5)
- Photos upload via LiveView `allow_upload` with progress indicator
- Uploaded to S3-compatible storage (Tigris), keys saved on the Job resource
- Graceful fallback if upload fails — form still submittable without photos
- Preview thumbnails shown after upload
