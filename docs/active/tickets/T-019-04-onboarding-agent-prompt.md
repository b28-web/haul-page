---
id: T-019-04
story: S-019
title: onboarding-agent-prompt
type: task
status: open
priority: high
phase: ready
depends_on: [T-018-02]
---

## Context

Design and test the system prompt for the onboarding AI agent. The prompt must guide the conversation naturally — asking the right questions in the right order, handling tangents, and knowing when it has enough information.

## Acceptance Criteria

- System prompt in `priv/prompts/onboarding_agent.md` (loaded at runtime, not compiled in)
- Prompt instructs the agent to:
  - Introduce itself: "I'll help you set up your hauling business website in a few minutes"
  - Ask for business name first (anchor the conversation)
  - Naturally collect: owner name, phone, email, service area, services offered
  - Probe for differentiators: "What makes your business different?" / "How long have you been operating?"
  - Handle common hauler patterns: multi-service businesses, franchise vs independent, seasonal services
  - Know when to stop asking: all required fields collected → transition to "Ready to create your site?"
  - Stay focused: politely redirect off-topic conversation back to business info
  - Be warm but efficient — haulers are busy people, don't waste their time
- Prompt tested against 5+ simulated conversations with varied operator personas:
  - Terse owner who gives one-word answers
  - Chatty owner who volunteers everything at once
  - Owner who's unsure what services to list
  - Owner who wants to know pricing before giving info
  - Non-English-dominant speaker (simple language, clear questions)
- Prompt version tracked (v1, v2, etc.) for A/B testing later
