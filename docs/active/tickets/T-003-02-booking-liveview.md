---
id: T-003-02
story: S-003
title: booking-liveview
type: task
status: open
priority: high
phase: ready
depends_on: [T-003-01]
---

## Context

Build the `/book` page as a LiveView form. Customers submit their info and it creates a Job in `:lead` state.

## Acceptance Criteria

- `HaulWeb.BookingLive` serves at `GET /book`
- Form fields: name, phone, email (optional), address, item description, preferred dates
- Real-time validation (phx-change) with clear error messages
- On submit: calls `:create_from_online_booking` on Job resource
- Success: shows confirmation message with "we'll contact you" copy
- Mobile-optimized: large inputs, proper keyboard types (tel, email)
- Styled consistently with landing page (dark theme, same font)
