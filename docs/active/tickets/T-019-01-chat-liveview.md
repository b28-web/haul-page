---
id: T-019-01
story: S-019
title: chat-liveview
type: task
status: open
priority: high
phase: ready
depends_on: [T-018-03]
---

## Context

Build the LiveView chat interface for conversational onboarding. The operator types naturally, the AI responds with follow-up questions, and the structured profile builds up in a sidebar as the conversation progresses.

## Acceptance Criteria

- `/start` LiveView page (public, no auth)
- Chat UI:
  - Message bubbles (user right-aligned, AI left-aligned)
  - Text input with send button and Enter-to-submit
  - Streaming AI responses (tokens appear as they arrive via BAML streaming)
  - Auto-scroll to latest message
  - Typing indicator while AI is responding
- Mobile-responsive: works well at 375px width (most users will be on phone)
- Dark theme consistent with rest of app
- Conversation state held in LiveView process (no database persistence yet — that comes in T-019-03)
- System prompt loaded from config (not hardcoded in LiveView module)
- Rate limiting: max 50 messages per session to prevent abuse
