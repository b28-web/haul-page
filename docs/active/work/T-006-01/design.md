# T-006-01 Design: Content Resources

## Decision 1: UUID Type — uuid_primary_key vs uuid_v7

**Options:**
- A) `uuid_v7_primary_key :id` — as in content-system.md spec
- B) `uuid_primary_key :id` — as in existing Company/Job resources

**Decision: B — `uuid_primary_key :id`**

Rationale: Consistency with existing resources. The codebase already has 4 resources all using `uuid_primary_key`. The migration generator uses `gen_random_uuid()`. Switching to v7 would be an inconsistency. Can be changed project-wide later if needed.

## Decision 2: AshPaperTrail Scope

**Options:**
- A) All five resources (as AC states)
- B) Only SiteConfig and Page (as content-system.md suggests)
- C) SiteConfig, Page, and Endorsement (business-critical content)

**Decision: A — All five resources**

Rationale: The AC is explicit: "All resources have AshPaperTrail extension." AshPaperTrail is low-overhead (one version table per resource). Content is business-critical — knowing when a service description changed or a gallery item was modified has real value. Follow the AC.

## Decision 3: MDEx Dependency

**Options:**
- A) Add `mdex` now and implement markdown rendering in the Page `:edit` change
- B) Stub the body_html rendering (set body_html = body) and add mdex later
- C) Skip body_html population entirely, leave it nil until a later ticket

**Decision: B — Stub rendering**

Rationale: MDEx is a NIF-based dependency (Rust compilation). Adding it changes the build pipeline and could introduce compilation issues. The AC says "Resources compile and are callable from IEx" — it doesn't require markdown rendering to work. Stub the change to copy body into body_html as-is. A future ticket (T-006-02 or similar) can add MDEx properly. This keeps the ticket focused on schema + resource definitions.

## Decision 4: SiteConfig Singleton Pattern

**Options:**
- A) DB unique constraint (single-row table) — only one record per tenant schema
- B) Application-level enforcement — `read_one!` + upsert pattern
- C) Named singleton via a fixed slug/key column with unique constraint

**Decision: B — Application-level singleton**

Rationale: Ash doesn't have a built-in "singleton resource" pattern. A `read_one!` call is the standard way to get the singleton. The `:edit` action on an existing record is how it's updated. Creation happens in seeds/setup. No special DB constraint needed — tenant schema isolation already scopes it.

The SiteConfig needs a `:create_default` action for seeding (one-time creation per tenant). The `:edit` action handles all updates. `code_interface` with `define :current` makes querying ergonomic.

## Decision 5: Multitenancy — All Content Resources Tenant-Scoped

**Decision: Yes, all five resources are tenant-scoped**

Rationale: Content is per-operator. The entire system uses schema-per-tenant. Content resources follow the same pattern as User/Token/Job. No content is shared across tenants.

## Decision 6: Content.Loader Bridge Module

**Options:**
- A) Remove it and update application.ex
- B) Keep it as-is, let a future ticket clean up
- C) Keep it but add a deprecation note

**Decision: B — Keep as-is**

Rationale: The Loader is used by the scan page LiveView (T-005-01 chain). Removing it could break existing code. The scan page ticket will migrate from Loader to Ash queries when it's ready. This ticket's scope is defining resources, not migrating consumers.

## Decision 7: Endorsement Source Type

**Options:**
- A) Inline `:atom` with `one_of` constraint (as in content-system.md)
- B) Separate `Ash.Type.Enum` module (like `Haul.Accounts.User.Role`)

**Decision: B — Separate enum module**

Rationale: Existing pattern in codebase uses `Haul.Accounts.User.Role` as a separate module for enum types. Follow the same convention. Cleaner, reusable, shows up properly in introspection.

## Decision 8: Service/GalleryItem Active Filter

The spec shows a preparation that filters `active == true` on `:read`. This means reads never return inactive items.

**Decision: Keep the filter preparation but add a separate `:read_all` action**

Rationale: Admin UI will need to see inactive items too. The default `:read` filters to active-only (public-facing). A `:read_all` action (or `:list_all`) bypasses the filter for admin use. This is a minor addition that prevents a common pain point.

Actually, re-reading the AC — it just says "Pre-sorted/filtered via preparations" for Service. Keep it simple: just the preparation on default read. Admin actions can come in the admin UI ticket.

**Revised: Default read with preparation only. No `:read_all` action.**

## Decision 9: Page Publish Workflow

The spec defines `:draft`, `:edit`, `:publish`, `:unpublish` actions. The body_html rendering happens in `:edit`.

**Decision: Also render body_html in `:draft` (create action)**

Rationale: When a page is created, it should have body_html populated even if not published. The rendering change should apply to both create and edit.

## Architecture Summary

```
lib/haul/content.ex                          # Ash Domain
lib/haul/content/site_config.ex              # SiteConfig resource
lib/haul/content/service.ex                  # Service resource
lib/haul/content/gallery_item.ex             # GalleryItem resource
lib/haul/content/endorsement.ex              # Endorsement resource
lib/haul/content/endorsement/source.ex       # Source enum type
lib/haul/content/page.ex                     # Page resource
config/config.exs                            # Add Haul.Content to ash_domains
priv/repo/tenant_migrations/                 # Generated migrations
priv/resource_snapshots/                     # Generated snapshots
test/haul/content/                           # Resource tests
```
