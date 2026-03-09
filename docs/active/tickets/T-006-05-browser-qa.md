---
id: T-006-05
story: S-006
title: browser-qa
type: task
status: open
priority: medium
phase: done
depends_on: [T-006-04]
---

## Context

Automated browser QA for the content domain story. Verify that content-driven pages render correctly after seeding — services, gallery, endorsements, and markdown pages all display properly.

## Test Plan

1. `just dev` — ensure dev server is running
2. Seed content: `mix haul.seed_content` (if not already seeded)
3. Navigate to `http://localhost:4000/` and verify:
   - Services grid populated with seeded service data (titles match seed files)
   - Service descriptions render correctly
4. Navigate to `/scan` and verify:
   - Gallery items show seeded before/after data
   - Endorsements show seeded testimonials with ratings
5. Test any markdown content pages (e.g. `/about`, `/faq` if they exist):
   - Rendered HTML present (not raw markdown)
   - Headings, paragraphs, lists render correctly in snapshot
6. Check server logs — no rendering errors, no missing template warnings

## Acceptance Criteria

- Seeded content renders on all public pages
- Markdown pages produce valid HTML output
- No 500 errors or template warnings in server logs
