---
id: T-027-02
story: S-027
title: resource-factories
type: task
status: open
priority: medium
phase: done
depends_on: [T-027-01]
---

## Context

Test files that create services, gallery items, endorsements, jobs, and other domain resources repeat Ash changeset boilerplate. With the core factory in place (T-027-01), adding resource-level factories is straightforward.

## Acceptance Criteria

- Add resource factory functions to `Haul.Test.Factories`:
  - `build_service(tenant, attrs \\ %{})` — creates a Service with defaults (title, description, price_cents, sort_order)
  - `build_gallery_item(tenant, attrs \\ %{})` — creates a GalleryItem with defaults
  - `build_endorsement(tenant, attrs \\ %{})` — creates an Endorsement with defaults
  - `build_site_config(tenant, attrs \\ %{})` — creates or updates SiteConfig
  - `build_job(tenant, attrs \\ %{})` — creates a Job in `:lead` state with defaults
  - `build_page(tenant, attrs \\ %{})` — creates a Page with defaults
- Each factory provides sensible defaults that can be overridden via `attrs`
- Defaults use unique values where needed (e.g., `"Test Service #{unique_int}"`)
- Migrate 5-10 test files to use the new resource factories as proof of concept:
  - Pick files from `test/haul/content/`, `test/haul/operations/`, and 2-3 LiveView test files
  - Replace inline `Ash.Changeset.for_create` blocks with factory calls
  - Verify tests still pass after each migration
- Document factory usage in a `@moduledoc` on `Haul.Test.Factories`

## Implementation Notes

- Resource factories should call Ash actions (not raw Ecto) to ensure validations and defaults are applied
- Use `authorize?: false` in factories — tests that need authorization testing should set up policies explicitly
- Don't add factories for resources that are only created in 1-2 test files — wait until there's actual duplication
