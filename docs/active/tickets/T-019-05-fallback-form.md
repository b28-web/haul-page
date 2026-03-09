---
id: T-019-05
story: S-019
title: fallback-form
type: task
status: open
priority: medium
phase: done
depends_on: [T-019-01, T-015-01]
---

## Context

Not everyone wants to chat with an AI. Provide a graceful fallback to the manual signup form when the LLM is unavailable or the operator prefers a traditional form.

## Acceptance Criteria

- "Prefer a form? Sign up manually" link on the `/start` chat page
- If LLM API returns error on first message: auto-redirect to `/signup` with flash "Chat is temporarily unavailable — use this form instead"
- If LLM API key is not configured: `/start` redirects to `/signup` silently
- Manual signup form (S-015) and chat onboarding both feed into the same provisioning pipeline
- Operator can switch mid-conversation: "Fill out a form instead" link always visible in chat
