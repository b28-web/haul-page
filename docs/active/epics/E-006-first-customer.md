---
id: E-006
title: first-customer
status: active
---

## First Customer Onboarding

The product isn't real until someone uses it. Every technical decision should be evaluated against: "can we hand this to a junk hauler this week?"

## Ongoing concerns

- Demo instance is always live and presentable (seed data looks real, not lorem ipsum)
- Onboarding a new operator is a single `flyctl deploy` + `fly secrets set` — under 30 minutes
- Seed content reflects a believable local business (real-sounding name, local area, realistic services)
- The landing page, scan page, and booking form work end-to-end without auth or operator app
- Print-as-poster actually produces something a hauler would tape to a laundromat bulletin board
- QR code on printed materials resolves to the scan page and works
- Booking form submissions are visible somewhere (email notification, admin page, or at minimum the DB)
- First customer feedback loops back into tickets — their friction is our roadmap
