# T-006-05 Research: Browser QA for Content Domain

## Ticket Scope

Automated browser QA for content-driven pages. Verify seeded content renders correctly on all public pages — services, gallery, endorsements, and markdown pages.

## Public Routes (router.ex)

| Route | Handler | Content rendered |
|-------|---------|-----------------|
| `GET /` | PageController :home | SiteConfig (business name, phone, tagline), Services grid |
| `LIVE /scan` | ScanLive | SiteConfig, GalleryItems (before/after), Endorsements (stars) |
| `LIVE /book` | BookingLive | SiteConfig (phone, business name) |
| `GET /scan/qr` | QRController | QR code SVG/PNG (no content data) |
| `GET /healthz` | HealthController | Plain text (no content) |

**No route exists for markdown Pages** (`/about`, `/faq`). The Page resource and seed files exist, but no controller/route serves them. The test plan mentions "if they exist" — they don't.

## Content Pipeline

1. Seed files in `priv/content/` (YAML + Markdown)
2. `mix haul.seed_content` → `Seeder.seed!(tenant)` → Ash resources created per tenant
3. `ContentHelpers` module queries Ash resources with fallback to operator config
4. Controllers/LiveViews call ContentHelpers in mount

## Seeded Data Summary

- **SiteConfig:** "Junk & Handy", phone "(555) 123-4567", tagline, service area
- **Services (6):** Junk Removal, Furniture Pickup, Appliance Hauling, Yard Waste, Construction Debris, Estate Cleanout
- **GalleryItems (3):** Garage cleanout (featured), Backyard debris, Office furniture — each with before/after URLs and captions
- **Endorsements (4):** Jane D. (5★ Google), Mike R. (5★ Yelp), Sarah K. (5★ Google), Tom B. (4★ Direct)
- **Pages (2):** about.md, faq.md — seeded but not routed

## Content Rendering (from T-006-04)

T-006-04 wired all three page handlers to use ContentHelpers:
- **PageController.home:** `load_site_config/1`, `load_services/1` → template renders service grid
- **ScanLive:** `load_site_config/1`, `load_gallery_items/1`, `load_endorsements/1` → gallery + endorsement sections
- **BookingLive:** `load_site_config/1` → phone and business name display

`get_field/2` helper in each module handles both Ash struct field access and map access uniformly.

## Gallery Image URLs

Gallery seed data references image URLs like `/uploads/tenant_junk-and-handy/gallery/...`. These files may or may not exist in dev. The ScanLive template has `onerror` fallback — missing images show a placeholder icon instead of broken img tags.

## Existing Browser QA Pattern (T-003-04 reference)

The booking form QA (T-003-04) used Playwright MCP to:
1. Navigate to pages
2. Take snapshots (accessibility tree)
3. Verify elements present (headings, fields, content text)
4. Test interactions (fill, submit, reset)
5. Check mobile viewport (375×812)
6. Verify server logs clean

No screenshots were stored as test artifacts — just markdown progress notes.

## Dev Server Prerequisites

- `just dev` must be running on port 4000
- Tenant must be provisioned (Company created → schema exists)
- Content must be seeded (`mix haul.seed_content`)
- T-003-04 already provisioned tenant "junk-and-handy" in dev DB

## Key Files

- `lib/haul_web/router.ex` — routes (no /about or /faq)
- `lib/haul_web/controllers/page_controller.ex` — landing page
- `lib/haul_web/controllers/page_html/home.html.heex` — landing template
- `lib/haul_web/live/scan_live.ex` — scan page with gallery/endorsements
- `lib/haul_web/live/booking_live.ex` — booking form
- `lib/haul_web/content_helpers.ex` — data loading
- `lib/haul/content/seeder.ex` — seed logic
- `priv/content/` — seed data files

## Constraints

- Playwright MCP available for browser automation
- No markdown page route → test plan step 5 (markdown pages) will be N/A or noted as not yet implemented
- Gallery images likely 404 in dev (placeholder fallback expected)
- Must verify seeded Ash data renders, not just hardcoded fallback data
