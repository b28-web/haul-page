---
id: T-002-01
story: S-002
title: landing-page-markup
type: task
status: open
priority: high
phase: ready
depends_on: [T-002-03]
---

## Context

Build the public landing page at `/`. Server-rendered HEEx, no LiveView. Translates the React/Lovable prototype into Phoenix templates.

Reference: `/tmp/mockup-repo/src/` (React prototype — design source, not code to keep)

## Design (from prototype)

Four sections, stacked vertically, centered, max-w-4xl:

1. **HeroSection** — Eyebrow ("Licensed & Insured · Serving Your Area"), giant "Junk Hauling" (Oswald, 6xl→9xl), subtitle "& Handyman Services", tagline paragraph, "Call for a free estimate" label, phone number as oversized tel: link (5xl→7xl), email + location row with icons
2. **ServicesGrid** — "What We Do" heading, 2×3 grid (2-col mobile, 3-col desktop). Each: icon + title (bold) + one-line description. Services: Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help
3. **WhyUsSection** — "Why Hire Us" heading, dash-prefixed list in 2-col layout. 6 items: same-day availability, upfront pricing, licensed/insured, we clean up, locally owned, free estimates
4. **FooterSection** — "Ready to Get Started?" CTA with phone button + "Print as Poster" button (screen only). Tear-off strip (print only): 8 vertical tabs with business name, "10% OFF", phone number

## Acceptance Criteria

- Route `GET /` serves a server-rendered page (PageController, not LiveView)
- All four sections rendered with correct typography (Oswald display, Source Sans 3 body)
- Dark theme: bg `hsl(0 0% 6%)`, fg `hsl(0 0% 92%)`, muted `hsl(0 0% 55%)`
- Phone number is a `tel:` link, email is a `mailto:` link
- Icons: use Heroicons (Phoenix default) or SVG equivalents of Lucide icons from prototype
- Responsive: 320px–1440px, mobile-first
- No JavaScript required — page works with JS disabled
- Operator config (business name, phone, email, tagline, service area, services list) wired from runtime config
- "Print as Poster" button calls `window.print()` (progressive enhancement — button hidden without JS, page still printable)
