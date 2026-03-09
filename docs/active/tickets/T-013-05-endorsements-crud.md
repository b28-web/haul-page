---
id: T-013-05
story: S-013
title: endorsements-crud
type: task
status: open
priority: low
phase: ready
depends_on: [T-013-01, T-006-01]
---

## Context

Let the operator manage customer endorsements/testimonials displayed on the scan page.

## Acceptance Criteria

- `/app/content/endorsements` LiveView
- List view: all endorsements with customer name, excerpt, source
- Add/edit form: customer_name, text, source (Google, Yelp, Direct, etc.), rating (optional)
- Delete with confirmation
- Reorder via sort_order
- Changes reflect on scan page immediately
