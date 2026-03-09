---
id: S-019
title: conversational-onboarding
status: open
epics: [E-011, E-003, E-010]
---

## Conversational Onboarding (Phase 2)

Build a LiveView chat interface where a prospective operator has a natural conversation with an AI agent that collects their business information. The agent asks smart questions, handles freeform answers, and builds a structured operator profile in real-time.

## Scope

- `/start` LiveView chat page (public, no auth required)
- Streaming LLM responses rendered in chat bubbles (via BAML streaming support)
- System prompt: you're an onboarding specialist for a hauling business platform. Collect: business name, owner name, phone, email, services offered, service area, what makes them different, years in business.
- BAML extraction runs after each user message — sidebar shows profile building up in real-time
- Profile completeness indicator ("we still need: service area, phone number")
- When profile is complete: "Ready to create your site?" confirmation
- On confirm: provisions tenant using same pipeline as `mix haul.onboard`
- Conversation stored for audit (linked to Company once created)
- Graceful degradation: "Having trouble? Fill out the form instead" link to manual signup (S-015)
- Mobile-first: chat interface works well on phone screens
