---
id: T-019-03
story: S-019
title: conversation-persistence
type: task
status: open
priority: medium
phase: done
depends_on: [T-019-01]
---

## Context

Persist conversations so they survive page refreshes and can be linked to the Company once provisioned. Also needed for audit and debugging extraction quality.

## Acceptance Criteria

- Ash resource: `Haul.AI.Conversation`
  - Fields: id, session_id (UUID), messages (array of maps), extracted_profile (map), status (active/completed/abandoned), company_id (nullable FK)
  - Created on first user message with a session_id stored in browser cookie
- Page refresh with valid session_id resumes the conversation
- On tenant provisioning: link conversation to Company record
- Conversations older than 30 days with status :abandoned are cleaned up (Oban cron job)
- Messages include: role (user/assistant/system), content, timestamp
- No PII in server logs — conversation content stays in the database only
