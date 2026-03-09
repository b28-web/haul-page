---
id: E-011
title: ai-onboarding
status: pending
---

## AI-Assisted Operator Onboarding

Use LLMs + BAML to make operator onboarding conversational and effortless. A new hauler chats with an AI agent that extracts their business information, generates professional content, and provisions a working site — all from a single conversation.

### Phased approach

**Phase 1 — BAML Foundation.** Integrate `baml_elixir` (Rustler NIF) into the Phoenix app. Define BAML types that mirror the operator profile schema (Company, SiteConfig, Services, Endorsements). Build the extraction pipeline: unstructured text in → typed Elixir structs out. Validate with unit tests against sample conversations.

**Phase 2 — Conversational Onboarding.** Build a LiveView chat interface where a prospective operator talks to an LLM agent. The agent asks the right questions (business name, services offered, service area, what makes them different), handles natural language answers, and builds a structured profile. The conversation is streamed, the extracted profile previewed in real-time alongside the chat.

**Phase 3 — Content Generation & Auto-Provisioning.** The LLM generates professional content from the conversation: service descriptions, tagline, "why hire us" bullet points, sample endorsement prompts. The extracted + generated data flows through BAML type validation, provisions a tenant, seeds content, and the operator sees their live site before the conversation ends.

### Technical approach

- **BAML runtime via `baml_elixir`** — Rustler NIF embeds the BAML Rust runtime in the BEAM. No sidecar, no REST hop. Handles prompt rendering, LLM API calls, and structured output parsing (Schema-Aligned Parsing).
- **`.baml` function definitions** — typed inputs/outputs for each extraction and generation task. BAML's SAP handles broken JSON, markdown wrapping, and type coercion from LLM responses.
- **Evaluate `ash_baml`** — if stable, use it to wire BAML functions as Ash actions for tighter domain integration.
- **LLM provider:** Anthropic Claude (primary), OpenAI (fallback). API keys in Fly secrets.

## Ongoing concerns

- LLM costs must stay within the free-tier budget — use Claude Haiku for extraction, Sonnet only for content generation
- Conversation data is PII (business owner info) — same tenant isolation rules apply
- Graceful fallback: if LLM is down or quota exceeded, offer the manual signup form (S-015)
- BAML type validation must catch hallucinated/invalid data before it hits the database
- `baml_elixir` is pre-release (1.0.0-pre.25) — pin version, monitor for breaking changes
- Pre-compiled NIF binaries must work on Fly.io (Linux x86_64) — verify in CI/Docker build
