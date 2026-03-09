# T-017-01 Design: Domain Settings UI

## Decision: Domain Status Tracking

### Option A: Add `domain_status` atom field to Company
- New attribute: `:domain_status` with values `nil | :pending | :verified | :provisioning | :active`
- Requires migration
- Clean querying and state display
- **Selected**

### Option B: Compute from `domain` + `domain_verified_at` timestamp
- No new enum, but logic spread across code
- Harder to represent "provisioning TLS" state
- Rejected: more complex, less explicit

### Option C: Separate DomainConfig resource
- Over-engineered for a single string + status
- Rejected: unnecessary indirection

**Rationale:** A simple atom field on Company is consistent with `subscription_plan`. The status values map directly to UI states. Migration is trivial.

## Decision: DNS Verification

### Option A: Inline `:inet_res.lookup` on button click
- Synchronous CNAME lookup in handle_event
- Simple, no Oban dependency
- May timeout on slow DNS (use 5s timeout)
- **Selected** for this ticket

### Option B: Oban worker for background DNS check
- Async, with polling or PubSub for result
- More robust but over-engineered for MVP
- T-017-02 can upgrade to this if needed

**Rationale:** DNS lookups are fast (<1s typically). A synchronous check with a timeout is simpler and gives immediate feedback. The "Verify DNS" button triggers a single lookup, shows result inline.

## Decision: UI Layout

Single-page LiveView at `/app/settings/domain` with states:

1. **Starter plan (gated):** Upgrade prompt card → link to `/app/settings/billing`
2. **No domain configured:** Show current subdomain + "Add Custom Domain" form
3. **Domain pending verification:** Show domain, CNAME instructions, "Verify DNS" button
4. **Domain verified/active:** Show domain with green badge, "Remove Domain" button

No wizard needed — single page with conditional rendering based on `company.domain` and `company.domain_status`.

## Decision: Sidebar Navigation

Add "Domain" link under Settings in the sidebar, indented like Content subsection. Only show when on `/app/settings` path. This keeps the nav clean — Settings expands to show Billing and Domain when active.

## Decision: Domain Validation

- Strip protocol prefix (http://, https://) if entered
- Strip trailing slashes/paths
- Validate hostname format: `~r/^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$/i`
- Reject bare TLDs (must have at least one dot)
- Reject the base_domain itself (can't use haulpage.com as custom domain)
- Downcase the input

## Decision: Remove Domain Flow

- Show confirmation modal (like billing downgrade)
- On confirm: clear `domain` and `domain_status` via `update_company`
- No TLS cleanup in this ticket (T-017-02 scope)

## Rejected Alternatives

- **Real-time DNS polling with PubSub**: Over-engineered for button-click verification
- **Multiple domain support**: Spec says single custom domain per company
- **SSL certificate display**: T-017-02 scope, not this UI ticket
