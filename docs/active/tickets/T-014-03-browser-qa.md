---
id: T-014-03
story: S-014
title: browser-qa
type: task
status: open
priority: medium
phase: done
depends_on: [T-014-01]
---

## Context

Verify that CLI-onboarded operators get a working site. Run `mix haul.onboard` then use Playwright MCP to confirm the new tenant's site is live and functional.

## Test Plan

1. Run `mix haul.onboard --name "Test Hauling" --phone 555-0199 --email test@example.com --area "Portland, OR"` in a test context
2. Navigate to the generated subdomain URL
3. Verify landing page renders with "Test Hauling" business name, correct phone, services grid
4. Navigate to `/scan` — verify scan page loads with default gallery/endorsements
5. Navigate to `/book` — verify booking form loads and accepts input
6. Resize to mobile — verify responsive layout
7. Verify the owner user can log in to `/app`

## Acceptance Criteria

- CLI-provisioned tenant has a fully functional public site
- Default content renders professionally (not Lorem Ipsum)
- Owner can access admin UI
