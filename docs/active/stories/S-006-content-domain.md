---
id: S-006
title: content-domain
status: open
epics: [E-005, E-003, E-007, E-008]
---

## Content Domain

Build the Content Ash domain — the operator-editable content layer. Schema-driven collections with markdown support, image handling, and a seed-from-files workflow.

Design: [docs/knowledge/content-system.md](../knowledge/content-system.md)

## Scope

- Content domain with resources: SiteConfig, Service, GalleryItem, Endorsement, Page
- Markdown rendering via MDEx (write-time caching in body_html)
- Seed task: `mix haul.seed_content` reads from `priv/content/`
- Seed files for dev: site_config.yml, services/*.yml, endorsements/*.yml, pages/*.md
- Landing page and scan page read from content resources instead of hardcoded data
