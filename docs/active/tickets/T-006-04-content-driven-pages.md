---
id: T-006-04
story: S-006
title: content-driven-pages
type: task
status: open
priority: high
phase: done
depends_on: [T-006-03, T-002-01]
---

## Context

Wire the landing page and scan page to read from content resources instead of hardcoded data. The templates should query Ash resources and render the results.

## Acceptance Criteria

- Landing page controller reads SiteConfig and Services from Ash, passes to template as assigns
- Service grid renders from `@services` assign (not hardcoded list)
- Business name, phone, tagline, email, service area all come from `@site_config`
- Scan page LiveView reads GalleryItems and Endorsements from Ash on mount
- Gallery renders from `@gallery_items`, endorsements from `@endorsements`
- Footer tear-off tabs read coupon text from SiteConfig
- If no content exists (empty DB), pages render gracefully with fallback copy
- Page works identically to before — no visual regression
