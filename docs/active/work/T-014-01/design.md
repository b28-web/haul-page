# T-014-01 Design: mix haul.onboard

## Decision: Core logic in Haul.Onboarding module, thin wrappers in Mix task + Release

### Option A: All logic in Mix task
- Pro: Simple, one file
- Con: Can't reuse from Release.onboard/1 in production. Duplicates logic.
- **Rejected**

### Option B: Core logic in Haul.Onboarding, wrappers call it
- Pro: Single source of truth. Mix task handles IO/prompts, Release.onboard calls the same core.
- Con: One extra module
- **Chosen** — clean separation, testable core

### Option C: Logic in Company resource as a custom action
- Pro: Keeps it in Ash domain
- Con: Onboarding spans multiple domains (Accounts + Content). Doesn't fit single-resource action.
- **Rejected**

## Core API Design

```elixir
Haul.Onboarding.run(%{name: "Joe's Hauling", phone: "555-1234", email: "joe@ex.com", area: "Seattle, WA"})
# => {:ok, %{company: company, user: user, content: summary, tenant: schema}}
# => {:error, step, reason}
```

Steps inside `run/1`:
1. Derive slug from name
2. Find existing company by slug (for idempotency) OR create new
3. Seed default content via `Content.Seeder.seed!/2`
4. Update SiteConfig with operator's phone/email/area
5. Find or create owner User with email + role :owner
6. Return result tuple

## Idempotency Strategy

- **Company**: Check by slug first. If exists, use it (don't re-create). Update name if changed.
- **Content**: Seeder is already idempotent (upserts by natural key).
- **SiteConfig**: Update with operator-specific phone/email/area after seeding defaults.
- **User**: Check by email in tenant. If exists, skip creation.

## Rollback Strategy

Wrap the multi-step process. If content seeding or user creation fails after company creation:
- Company + schema already exist (DDL committed) — can't roll back schema creation in a transaction
- Practical approach: let the company persist (idempotent re-run fixes it). Log the error clearly.
- For truly catastrophic failures, provide `mix haul.onboard --cleanup slug` (future, not this ticket)

The idempotent design means "rollback" = "fix the issue and re-run." This is more robust than transactional rollback for DDL operations.

## User Creation

User resource has AshAuthentication policies that require an actor. Options:
1. Use `authorize?: false` context — bypasses policies for seed/admin operations
2. Use Ash bulk action with system actor

**Decision: `authorize?: false`** — This is an admin provisioning task, not a user-facing flow. Same pattern as seed tasks.

For the "magic link invite," the sender is stubbed. The task will:
1. Create user with a temporary password (or no password, relying on magic link)
2. Print a note that magic link email sending is TODO
3. When magic link sender is implemented, the task will trigger it

## Interactive Mode

Use `Mix.shell().prompt/1` for interactive prompts. Required fields: name, phone, email, area. Each prompt validates input (non-empty for required fields).

## Non-interactive Mode

OptionParser with `--name`, `--phone`, `--email`, `--area` flags. All four required in non-interactive mode.

## Output

Success prints:
```
✓ Company created: "Joe's Hauling" (joe-s-hauling)
✓ Tenant schema provisioned: tenant_joe-s-hauling
✓ Content seeded: 6 services, 3 gallery items, 4 endorsements
✓ Owner user created: joe@ex.com
Site live at https://joe-s-hauling.haulpage.com
```

Error prints the step that failed and the error message.
