---
id: E-007
title: demo-instance
status: active
---

## Demo Instance Health

A permanently-running demo at a public URL that sells the product by being the product. This is the pitch deck — a hauler visits the URL, sees what their site would look like, and says "I want that."

## Ongoing concerns

- Demo is deployed and accessible (not scaled-to-zero — first impression can't be a 3s cold start)
- Seed data tells a story: a fictional but plausible operator with real-looking gallery photos, endorsements, services
- Booking form works but submissions go to a test inbox (not a real operator's phone)
- Print poster looks good on paper — tested periodically
- QR code on demo poster resolves to demo scan page
- Demo stays current with main branch — auto-deploys on merge
- Demo URL is shareable in conversations with prospective operators
