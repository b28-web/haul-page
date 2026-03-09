# T-013-02 Design: Site Config Editor

## Decision: Create-or-Update Form Pattern

### Problem

SiteConfig may or may not exist for a tenant. The form must handle both cases transparently.

### Options

**A. Detect on mount, use for_create or for_update accordingly**
- On mount, try to load SiteConfig for tenant
- If exists: `AshPhoenix.Form.for_update(config, :edit, ...)`
- If not: `AshPhoenix.Form.for_create(SiteConfig, :create_default, ...)`
- On successful create, switch to update form for subsequent saves

**B. Ensure SiteConfig always exists (seed on tenant creation)**
- Modify tenant provisioning to always create a default SiteConfig
- Form always uses `for_update`

**C. Use a custom upsert action**
- Add an `:upsert` action to SiteConfig that creates or updates

### Decision: Option A

Option A is simplest — no schema changes, no migration, works with existing data. The create-vs-update detection is straightforward. After the first save creates the record, subsequent saves update it. Option B would be cleaner long-term but requires migration work outside this ticket's scope.

## Decision: Tenant Derivation

AuthHooks sets `current_company` (Company struct with `slug`). Need tenant schema string.

Use `ProvisionTenant.tenant_schema(company.slug)` — same pattern used in tests and ContentHelpers. Derive it in `mount/3`.

## Decision: Field Set

AC specifies 6 fields: business_name, phone, email, tagline, service_area, primary_color.

SiteConfig has additional fields (address, coupon_text, meta_description, logo_url). Include all editable fields in the form — the AC lists the minimum, but showing all fields improves operator utility with zero additional effort. Each field maps directly to an existing attribute.

Final field set for the form:
- business_name (text, required)
- phone (tel, required)
- email (email)
- tagline (text)
- service_area (text)
- address (text)
- primary_color (text/color)
- coupon_text (text)
- meta_description (textarea)

Omit `logo_url` — requires file upload, separate ticket concern.

## Decision: Form Layout

Single-column form, mobile-first. Group related fields:
1. **Business info** — business_name, tagline, phone, email
2. **Location** — address, service_area
3. **Appearance** — primary_color, coupon_text
4. **SEO** — meta_description

Use section headings within the form. Save button at bottom.

## Decision: Validation

Use AshPhoenix.Form real-time validation via `phx-change="validate"`. Ash handles required field validation (business_name, phone). No custom client-side validation needed.

## Decision: Success Behavior

On save:
- Flash `:info` with "Site settings updated"
- Stay on page (no redirect)
- Form remains populated with saved values
- If was a create, switch internal state to update form

## Decision: Route Path

`/app/content/site` — nested under `/app/content` so the Content sidebar link highlights correctly (uses `String.starts_with?(@current_path, "/app/content")`).

## Rejected Alternatives

- **Modal form** — rejected; too constrained for 9+ fields
- **Inline editing** — rejected; more complex, no benefit for settings page
- **Color picker component** — rejected for now; text input with hex value is sufficient. Can enhance later.
- **Auto-save** — rejected; explicit save button is clearer for settings
