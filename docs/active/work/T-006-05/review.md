# T-006-05 Review — Browser QA for Content Domain

## Summary

Browser QA verification of content-driven pages after seeding. All public pages that render content (`/`, `/scan`, `/book`) were tested via Playwright MCP at desktop (1280×800) and mobile (375×812) viewports. All seeded content renders correctly from Ash resources.

## What Changed

No code changes. This is a QA-only ticket. Artifacts produced:
- `docs/active/work/T-006-05/research.md`
- `docs/active/work/T-006-05/design.md`
- `docs/active/work/T-006-05/structure.md`
- `docs/active/work/T-006-05/plan.md`
- `docs/active/work/T-006-05/progress.md`
- `docs/active/work/T-006-05/review.md`

## Test Results

| Page | Content Source | Verified |
|------|--------------|----------|
| `/` (landing) | SiteConfig: business name, phone, email, tagline, service area | ✅ |
| `/` (landing) | Services: all 6 seeded titles + descriptions from Ash | ✅ |
| `/scan` (scan) | SiteConfig: business name, phone, service area | ✅ |
| `/scan` (scan) | GalleryItems: 3 items with captions, before/after pairs | ✅ |
| `/scan` (scan) | Endorsements: 4 customers with quotes and star ratings | ✅ |
| `/book` (booking) | SiteConfig: phone CTA | ✅ |
| Mobile (375×812) | All above content at mobile viewport | ✅ |
| Server health | No 500s, no template warnings | ✅ |

## Test Coverage Assessment

**Programmatic test coverage (ExUnit):** 135 tests covering:
- Content resource CRUD (page, service, gallery_item, endorsement, site_config)
- Seeder idempotency
- PageController integration with tenant provisioning + seeded content
- ScanLive integration with tenant provisioning + seeded content
- BookingLive form validation, submission, photo upload

**Browser QA coverage (this ticket):** Visual/behavioral confirmation that:
- Seeded data from Ash resources (not fallback config) renders on all public pages
- ContentHelpers fallback works when no seeded data exists (observed before seeding)
- Gallery image 404s handled gracefully by onerror placeholder
- Mobile responsive layout intact with content-driven data

## Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| Seeded content renders on all public pages | ✅ Met | All 3 public content pages verified |
| Markdown pages produce valid HTML output | ⚠️ N/A | Pages seeded with rendered body_html but no route serves them |
| No 500 errors or template warnings | ✅ Met | Clean server logs throughout session |

## Open Concerns

1. **No route for markdown pages** — Page resources (about, faq) are seeded with rendered HTML (`body_html` field populated via MDEx), but no controller or route serves `/about` or `/faq`. A future ticket should add a `GET /:slug` or `GET /pages/:slug` route to PageController. The test plan anticipated this with "if they exist."

2. **Gallery images 404 in dev** — All 6 gallery image URLs (before/after for 3 items) return 404. The seed YAML files reference paths like `/images/gallery/before-1.jpg` but no actual files exist. The `onerror` placeholder fallback works, but for demo/production, actual images or the upload system (T-003-03) should populate these.

3. **Star ratings in accessibility snapshot** — The endorsement star ratings use SVG icons. The accessibility tree shows the icon structure but not explicit star count text. Screen readers may not interpret the rating. Consider adding `aria-label="5 out of 5 stars"` in a future accessibility ticket.

## Conclusion

All testable acceptance criteria are met. The content seeding pipeline works end-to-end: YAML/Markdown seed files → `mix haul.seed_content` → Ash resources → ContentHelpers queries → rendered on public pages. The two gaps (no markdown page route, no gallery images in dev) are pre-existing architectural gaps, not regressions from this story.
