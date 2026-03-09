# T-006-05 Progress — Browser QA for Content Domain

## Prerequisites

- Dev server: running on localhost:4000
- Tenant: "junk-and-handy" already provisioned (from T-003-04 session)
- Content seeding: ran `mix haul.seed_content` — created SiteConfig, 6 services, 3 gallery items, 4 endorsements, 2 pages

## Step 1: Landing Page (`/`) — Before Seeding — INFORMATIONAL

- First load showed **fallback** operator config data (Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help)
- This confirmed the ContentHelpers fallback mechanism works when no Ash data exists
- After running `mix haul.seed_content`, reloaded to verify seeded data

## Step 2: Landing Page (`/`) — After Seeding — PASS

- ✅ Business name: "Junk & Handy" (from SiteConfig)
- ✅ Phone: "(555) 123-4567" (from SiteConfig)
- ✅ Tagline: "We haul it all — fast, fair, and friendly." (from SiteConfig)
- ✅ Service area: "Greater Metro Area" (from SiteConfig)
- ✅ Email: "hello@junkandhandy.com" (from SiteConfig)
- ✅ All 6 seeded service titles:
  - Junk Removal
  - Furniture Pickup
  - Appliance Hauling
  - Yard Waste
  - Construction Debris
  - Estate Cleanout
- ✅ Each service has its seeded description text (not fallback text)
- ✅ HTTP 200, no errors

## Step 3: Scan Page (`/scan`) — Gallery — PASS

- ✅ "Our Work" heading present
- ✅ 3 gallery items rendered with captions from seed data:
  - "Backyard debris removal after storm damage"
  - "Full garage cleanout — hauled in one trip"
  - "Office furniture removal — desks, chairs, and filing cabinets"
- ✅ Before/After pairs present for each item
- ✅ Image 404s handled gracefully — placeholder fallback via `onerror` (6 image URLs 404, expected since no actual image files in dev)

## Step 4: Scan Page (`/scan`) — Endorsements — PASS

- ✅ "What Customers Say" heading present
- ✅ All 4 endorsements rendered with seeded data:
  - Jane D.: "Called in the morning, they were here by lunch..."
  - Mike R.: "Best price in town and they were careful with my floors..."
  - Sarah K.: "They cleared out my entire garage in under two hours..."
  - Tom B.: "Had a huge pile of construction debris from a kitchen reno..."
- ✅ Star rating icons rendered (filled stars visible in snapshot structure)
- ✅ Customer names with em-dash prefix (— Jane D., etc.)

## Step 5: Booking Page (`/book`) — SiteConfig — PASS

- ✅ Phone: "(555) 123-4567" in CTA section
- ✅ All form fields present and correctly labeled
- ✅ HTTP 200, no errors

## Step 6: Markdown Pages — N/A

- No routes exist for `/about` or `/faq`
- Page resources are seeded in DB (about.md, faq.md with rendered body_html)
- But no controller/route serves them — future ticket needed
- Test plan says "if they exist" — they don't, so this is expected N/A

## Step 7: Server Health — PASS

- No 500 errors during session
- All page loads returned HTTP 200
- Only console errors: 6 gallery image 404s (expected — no image files in dev)
- No template warnings or rendering errors
- LiveView mounts clean on /scan and /book

## Step 8: Mobile Viewport (375×812) — PASS

- Resized to 375×812 (iPhone X dimensions)
- Landing page (`/`): all content renders, single-column layout, no overflow
- Scan page (`/scan`): gallery and endorsements render correctly at mobile width
- All seeded content visible at mobile viewport

## Summary

| Step | Target | Result |
|------|--------|--------|
| Landing page — services | 6 seeded services | ✅ PASS |
| Landing page — SiteConfig | Business name, phone, tagline | ✅ PASS |
| Scan page — gallery | 3 gallery items with captions | ✅ PASS |
| Scan page — endorsements | 4 endorsements with quotes | ✅ PASS |
| Booking page — SiteConfig | Phone CTA | ✅ PASS |
| Markdown pages | Not routed | N/A |
| Server health | No 500s/warnings | ✅ PASS |
| Mobile viewport | No overflow | ✅ PASS |

**All testable acceptance criteria met. No code changes needed.**
