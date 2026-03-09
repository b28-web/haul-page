---
id: T-006-03
story: S-006
title: seed-task
type: task
status: open
priority: medium
phase: ready
depends_on: [T-006-02]
---

## Context

Build `mix haul.seed_content` — reads YAML/markdown files from `priv/content/` and upserts into content resources. This is the bridge between file-based authoring (dev) and DB-backed runtime (prod).

## Acceptance Criteria

- Mix task `mix haul.seed_content` exists and is idempotent (safe to run repeatedly)
- Reads `priv/content/site_config.yml` → upserts SiteConfig singleton
- Reads `priv/content/services/*.yml` → upserts Service records (matched by title)
- Reads `priv/content/endorsements/*.yml` → upserts Endorsement records
- Reads `priv/content/gallery/*.yml` → upserts GalleryItem records
- Reads `priv/content/pages/*.md` → parses YAML frontmatter + markdown body, upserts Page records (matched by slug)
- `yaml_elixir` added to deps for YAML parsing
- Dev seed files created with realistic content matching the mockup (6 services, 6 "why us" items, sample endorsements)
- `mix setup` alias includes `haul.seed_content`
