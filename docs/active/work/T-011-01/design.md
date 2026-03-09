# T-011-01 Design: Onboarding Runbook

## Goal

Produce `docs/knowledge/operator-onboarding.md` — a numbered, copy-paste-friendly runbook that takes someone from zero to a live operator instance in under 30 minutes.

## Design Decisions

### 1. Document Format

**Chosen:** Single markdown file with numbered steps, inline commands, and a reference appendix.

Rationale: The acceptance criteria specify `docs/knowledge/operator-onboarding.md`. A single file is easy to follow linearly. The appendix covers env vars and troubleshooting without breaking the flow.

### 2. Database Strategy: Separate Neon Projects

**Chosen:** One Neon project per operator.

**Rejected:** Neon branches within a single project.
- Branches share compute and storage quotas
- Isolation is weaker — a branch can see the parent's connection pool
- Billing is per-project anyway for prod workloads

Each operator gets their own Neon project with a dedicated connection string. Clean billing, full isolation, easy teardown.

### 3. Fly App Naming

**Chosen:** `fly deploy --app <operator-slug>` with the shared fly.toml.

**Rejected:** Copying and editing fly.toml per operator.
- Adds file management overhead
- fly.toml doesn't contain operator-specific config (secrets handle that)
- `--app` flag cleanly overrides the `app` field

Convention: app name = `haul-<operator-slug>` (e.g., `haul-acme`, `haul-portland-junk`).

### 4. Content Seeding via Release Eval

The seed_content Mix task delegates to `Haul.Content.Seeder.seed!/1`. In production (no Mix), we use release eval:

```bash
fly ssh console -C "/app/bin/haul eval '
  companies = Ash.read!(Haul.Accounts.Company)
  for c <- companies do
    tenant = Haul.Accounts.Changes.ProvisionTenant.tenant_schema(c.slug)
    Haul.Content.Seeder.seed!(tenant)
  end
'"
```

This works because the Seeder module is compiled into the release.

### 5. Seeding the Default Company

The `seeds.exs` file creates the default Company, but it's a Mix script. In production, the Company is created when the first user signs up or via release eval:

```bash
fly ssh console -C "/app/bin/haul eval '
  Haul.Accounts.Company
  |> Ash.Changeset.for_create(:create_company, %{name: \"Acme Hauling\", slug: \"acme\"})
  |> Ash.create!()
'"
```

This triggers `ProvisionTenant`, which creates the `tenant_acme` schema.

### 6. Verification Checklist

Post-deploy verification covers:
1. Health check (`curl /healthz`)
2. Landing page loads (visual check)
3. Booking form renders and submits
4. Print view works (for the coupon strip)

These map directly to the acceptance criteria.

### 7. Rollback Strategy

Two levels:
- **App rollback:** `fly releases` + `fly deploy --image <previous-image>`
- **Full teardown:** `fly apps destroy` + delete Neon project + remove DNS

Teardown is the escape hatch for a failed onboarding — clean up everything and start over.

### 8. Document Sections

1. **Prerequisites** — tools needed, accounts required
2. **Steps 1-8** — numbered, linear, copy-paste commands
3. **Env var reference** — table with all vars, descriptions, examples
4. **Rollback** — how to undo a failed deploy
5. **Teardown** — how to fully remove an operator
6. **Troubleshooting** — common issues and fixes
7. **Cost estimate** — per-operator monthly cost

### 9. Operator Slug Convention

Format: lowercase alphanumeric + hyphens. Used for:
- Fly app name: `haul-<slug>`
- Neon project name: `haul-<slug>`
- Postgres tenant schema: `tenant_<slug>`
- Default subdomain: `haul-<slug>.fly.dev`

### 10. What's Out of Scope

- Multi-operator CI/CD (one pipeline deploys one operator currently)
- Automated provisioning (that's T-014-01)
- Custom domain SSL (covered briefly, but DNS setup is operator-specific)
- Tigris bucket creation (optional, can add later)
- Integration setup (Stripe, Twilio, etc. — documented as optional post-setup)
