---
id: T-006-01
story: S-006
title: content-resources
type: task
status: open
priority: high
phase: done
depends_on: [T-004-01]
---

## Context

Define the Content Ash domain with five resources: SiteConfig, Service, GalleryItem, Endorsement, Page. These are the schema-driven content collections — equivalent to Astro's `defineCollection`.

Design reference: docs/knowledge/content-system.md

## Acceptance Criteria

- `Haul.Content` domain module with all five resources registered
- SiteConfig: singleton pattern, business identity fields, `:edit` action
- Service: title, description, icon, sort_order, active. Pre-sorted/filtered via preparations
- GalleryItem: before/after image URLs, caption, alt_text, featured flag
- Endorsement: customer_name, quote_text, star_rating (1–5), source enum, optional `belongs_to :job`
- Page: slug (unique identity), title, body (markdown), body_html (cached render), published/published_at
- All resources have AshPaperTrail extension
- Migrations generated and run successfully
- Resources compile and are callable from IEx
