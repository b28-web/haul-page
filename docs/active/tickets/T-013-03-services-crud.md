---
id: T-013-03
story: S-013
title: services-crud
type: task
status: open
priority: medium
phase: ready
depends_on: [T-013-01, T-006-01]
---

## Context

Let the operator manage their services list — add, edit, reorder, remove services that appear on the landing page.

## Acceptance Criteria

- `/app/content/services` LiveView
- List view: shows all services with title, description, drag-to-reorder
- Add/edit form: title, description, icon (select from predefined set)
- Delete with confirmation
- Reorder persists via `sort_order` field on Service resource
- Changes reflect on landing page services grid immediately
- Minimum 1 service required — cannot delete last one
