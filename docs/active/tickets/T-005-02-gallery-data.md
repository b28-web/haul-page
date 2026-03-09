---
id: T-005-02
story: S-005
title: gallery-data
type: task
status: open
priority: medium
phase: done
depends_on: [T-005-01]
---

## Context

The before/after gallery and endorsements need a data source. Start with operator config (static), design for database-backed later.

## Acceptance Criteria

- Gallery items configurable: before_photo_url, after_photo_url, caption (optional)
- Endorsements configurable: customer_name, quote_text, star_rating (1-5, optional), date (optional)
- Initial implementation: loaded from runtime config or a JSON/YAML file in `priv/`
- Data structure designed so it maps cleanly to an Ash resource later (GalleryItem, Endorsement)
- Photos served from `priv/static/images/` initially (Tigris later)
