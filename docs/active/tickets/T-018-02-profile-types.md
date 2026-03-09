---
id: T-018-02
story: S-018
title: profile-types
type: task
status: open
priority: high
phase: ready
depends_on: [T-018-01]
---

## Context

Define the BAML type system that represents an operator profile. These types are the contract between the LLM's unstructured output and our Ash resources — BAML's Schema-Aligned Parsing validates the bridge.

## Acceptance Criteria

- `baml/types/operator_profile.baml`:
  ```
  class OperatorProfile {
    business_name string
    owner_name string
    phone string
    email string
    service_area string
    tagline string?
    years_in_business int?
    services ServiceOffering[]
    differentiators string[]
  }

  class ServiceOffering {
    name string
    description string?
    category ServiceCategory
  }

  enum ServiceCategory {
    JUNK_REMOVAL
    CLEANOUTS
    YARD_WASTE
    REPAIRS
    ASSEMBLY
    MOVING_HELP
    OTHER
  }
  ```
- Types map cleanly to existing Ash resources (Company, SiteConfig, Service)
- Elixir structs generated or manually defined to mirror BAML types
- Mapping module: `Haul.AI.ProfileMapper` converts BAML output → Ash resource changesets
- Unit tests: valid profile → correct changesets, partial profile → lists missing fields
