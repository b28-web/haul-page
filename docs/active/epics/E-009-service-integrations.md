---
id: E-009
title: service-integrations
status: pending
---

## External Service Integrations

Third-party SaaS wired into the app for capabilities that must not be built in-house: transactional email, SMS, payments, and address autocomplete.

## Ongoing concerns

- API keys and secrets live in Fly secrets / runtime env vars — never in code or config files
- Every integration has a behaviour-based adapter so tests use in-memory fakes, not live API calls
- Outbound calls go through Oban jobs where delivery guarantees matter (email, SMS, webhooks)
- Rate limits and error handling follow each provider's retry guidance
- Costs stay within the < $15/mo operator budget at low-to-moderate volume
- Elixir-native libraries preferred: Swoosh (email), ExTwilio or req (SMS), Stripity Stripe (payments)
