---
id: T-005-01
story: S-005
title: scan-page-layout
type: task
status: open
priority: high
phase: done
depends_on: [T-002-02]
---

## Context

Build the `/scan` page — the QR code landing. Someone scanned a code off a truck, flyer, or door hanger. They're curious but uncommitted. The page needs to: (1) make it dead simple to call or book, and (2) show enough social proof to convert.

## Acceptance Criteria

- Route `GET /scan` serves a LiveView page
- Top section: operator name, "Scan to Schedule" heading, phone number as oversized tel: link, CTA button to `/book`
- Middle section: before/after photo gallery — side-by-side pairs, swipeable on mobile
- Bottom section: customer endorsements — name, short quote, optional star rating
- Same dark theme and typography as landing page
- Mobile-first — this is almost exclusively a phone experience
- Gallery and endorsements driven by config (hardcoded list initially, database-backed later)
