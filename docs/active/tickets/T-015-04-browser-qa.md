---
id: T-015-04
story: S-015
title: browser-qa
type: task
status: open
priority: high
phase: done
depends_on: [T-015-02, T-015-03]
---

## Context

Playwright MCP verification of the full self-service signup flow. This is the most critical user journey for SaaS growth — a hauler must go from marketing page to live site without friction.

## Test Plan

1. Navigate to bare domain `/` — verify marketing landing page loads (pricing, features, CTA)
2. Click "Get Started" — verify redirect to `/signup`
3. Fill signup form: business name, email, phone, service area
4. Verify real-time validation: slug preview updates, email uniqueness check
5. Submit — verify redirect to `/app/onboarding` wizard
6. Step through wizard: confirm info → choose subdomain → customize services → preview → go live
7. Verify "Your site is live!" confirmation
8. Navigate to the new subdomain — verify public site renders with entered business info
9. Mobile flow (375x812): repeat steps 2-7 — verify wizard is usable on phone
10. Navigate to marketing page pricing section — verify tier cards render correctly

## Acceptance Criteria

- Complete signup-to-live-site flow verified via Playwright MCP
- Time from signup click to live site is measurable (log timestamps)
- Mobile signup flow is smooth and usable
- Marketing page looks professional and has clear CTAs
