# T-011-01 Structure: Onboarding Runbook

## Files Changed

### Created

| File | Purpose |
|------|---------|
| `docs/knowledge/operator-onboarding.md` | The runbook — primary deliverable |

### Modified

None. This is a docs-only ticket.

### Deleted

None.

## Document Structure

```
docs/knowledge/operator-onboarding.md
├── Title + estimated time
├── Prerequisites
│   ├── Required tools (flyctl, Neon CLI or web UI)
│   ├── Required accounts (Fly.io, Neon, email provider)
│   └── Gather operator info checklist
├── Onboarding Steps (numbered 1-8)
│   ├── 1. Create Fly app
│   ├── 2. Create Neon database
│   ├── 3. Set secrets
│   ├── 4. Deploy
│   ├── 5. Run migrations (auto, but verify)
│   ├── 6. Create company + seed content
│   ├── 7. Add custom domain (optional)
│   └── 8. Verify
├── Environment Variable Reference
│   ├── Required table
│   ├── Operator identity table
│   └── Optional integrations table
├── Rollback & Teardown
│   ├── Rollback to previous release
│   └── Full teardown (destroy app + DB)
├── Troubleshooting
│   ├── Deploy fails
│   ├── Health check fails
│   ├── Database connection errors
│   └── Content not showing
└── Cost Estimate
```

## Content Guidelines

- Every step has a copy-paste shell command
- Placeholders use `<ANGLE_BRACKETS>` for values the operator must fill in
- Each step includes a verification sub-step ("you should see...")
- Rollback steps are explicit — not "undo the above" but actual commands
- Env var reference is a single table, not scattered through the doc
- Troubleshooting covers the 4 most common failure modes

## Dependencies

- No code changes required
- No test changes required
- The runbook references existing infrastructure (fly.toml, Dockerfile, release scripts)
- Content seeding references `Haul.Content.Seeder.seed!/1` which is already compiled into the release
