---
id: S-003
title: booking-form
status: open
epics: [E-003, E-004, E-006, E-008]
---

## Online Booking Form

Build the public booking form at `/book`. LiveView-powered, creates a Job in `:lead` state.

## Scope

- LiveView form: name, phone, address, item description, preferred dates
- Photo upload from mobile camera (input[capture])
- Real-time validation
- Creates Job resource (`:lead` state) on submit
- Confirmation page / message after submission
- Owner notification trigger (SMS/email via Oban — can be stubbed initially)
