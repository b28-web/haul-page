# T-011-01 Research: Onboarding Runbook

## Objective

Write a step-by-step runbook for deploying a new operator instance on Fly.io. This documents the manual process that T-014-01 (mix onboard CLI) will eventually automate.

## Existing Infrastructure

### Deployment Architecture

```
[Browser] → [Fly.io CDN/TLS] → [Phoenix on Fly VM] → [Neon Postgres]
                                        ↓
                                 [Fly Tigris S3]
```

Single Fly.io VM per operator. Scale-to-zero when idle. Cold start ~2-3s.

### fly.toml (Current Config)

- App: `haul-page`, region: `iad`
- VM: `shared-cpu-1x`, 256MB
- Health check: `GET /healthz` every 10s
- Auto-stop/start: enabled, min machines: 0
- Internal port: 4000, force HTTPS

**Note:** Each new operator needs a unique app name and separate fly.toml or `--app` flag.

### Dockerfile

Multi-stage build (Elixir 1.19.3 + OTP 28.4):
1. **deps** — fetch and compile deps
2. **build** — compile app, `mix assets.deploy`, `mix release`
3. **runtime** — minimal Debian with the release

Entry point: `/app/bin/migrate_and_start` (runs migrations, then starts Phoenix).

### Release Scripts (`rel/overlays/bin/`)

| Script | Purpose |
|--------|---------|
| `migrate_and_start` | Default entry point — migrate then start with `PHX_SERVER=true` |
| `migrate` | Run migrations only |
| `server` | Start server only (no migrate) |

### Release Module (`lib/haul/release.ex`)

- `Haul.Release.migrate()` — runs all pending migrations
- `Haul.Release.rollback(repo, version)` — rolls back to specific version

### Environment Variables

#### Required (prod crashes without these)

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Postgres connection string | `postgresql://user:pass@ep-xxx.neon.tech/haul?sslmode=require` |
| `SECRET_KEY_BASE` | Cookie/session signing key | `mix phx.gen.secret` output (64+ chars) |
| `PHX_HOST` | Public hostname | `acme-hauling.fly.dev` or `acmehauling.com` |
| `POSTMARK_API_KEY` or `RESEND_API_KEY` | Email delivery | Postmark server token |

#### Operator Identity

| Variable | Description | Example |
|----------|-------------|---------|
| `OPERATOR_BUSINESS_NAME` | Shown on landing page, emails | `Acme Hauling` |
| `OPERATOR_PHONE` | Contact number | `5551234567` |
| `OPERATOR_EMAIL` | Notification recipient | `info@acmehauling.com` |
| `OPERATOR_TAGLINE` | Landing page subtitle | `Fast, honest, affordable.` |
| `OPERATOR_SERVICE_AREA` | Geographic coverage | `Portland, OR & Surrounding Areas` |
| `OPERATOR_COUPON_TEXT` | Print coupon text | `$25 OFF` |

#### Optional Integrations

| Variable | Description | Needed for |
|----------|-------------|------------|
| `STRIPE_SECRET_KEY` | Payment processing | `/pay/:job_id` |
| `STRIPE_PUBLISHABLE_KEY` | Client-side Stripe | Payment Element |
| `STRIPE_WEBHOOK_SECRET` | Webhook signature | `payment_intent.succeeded` |
| `TWILIO_ACCOUNT_SID` | SMS notifications | Booking SMS alerts |
| `TWILIO_AUTH_TOKEN` | SMS auth | Required with SID |
| `TWILIO_FROM_NUMBER` | SMS sender | `+15551234567` |
| `GOOGLE_PLACES_API_KEY` | Address autocomplete | Booking form |
| `STORAGE_BUCKET` | Photo storage (Tigris) | Upload photos |
| `AWS_ACCESS_KEY_ID` | Tigris auth | With STORAGE_BUCKET |
| `AWS_SECRET_ACCESS_KEY` | Tigris auth | With STORAGE_BUCKET |

### Multi-Tenancy

- Schema-per-tenant via AshPostgres `:context` strategy
- `ProvisionTenant` change creates `tenant_{slug}` Postgres schema on Company creation
- Seeds (`priv/repo/seeds.exs`) create default Company from operator config
- Content seeder (`mix haul.seed_content`) populates SiteConfig, Services, Gallery, etc.

### Existing Documentation

`DEPLOYMENT.md` covers single-instance deploy but not multi-operator onboarding. It assumes the `haul-page` app name and doesn't cover:
- Per-operator app naming
- Database branching/isolation
- Content seeding for new operators
- Verification checklist
- Rollback/teardown

### Health Check

`GET /healthz` → 200 "ok" (plain text). Used by Fly.io for readiness.

### Cost Per Operator

| Component | Monthly |
|-----------|---------|
| Fly.io VM | $4-8 (scale-to-zero) |
| Neon Postgres | $5-15 |
| Fly Tigris | $0-2 |
| **Total** | **$10-25** |

### CI/CD

GitHub Actions: test → quality → deploy (on main push). Deploy uses `FLY_API_TOKEN` secret. Currently hardcoded to `haul-page` app — multi-operator CI is out of scope for this runbook.

## Key Constraints

1. **One Fly app per operator** — separate VM, separate secrets, separate domain
2. **Database isolation** — each operator gets a separate Neon project/branch (not just schema)
3. **Content seeding requires SSH** — `mix haul.seed_content` is a Mix task, needs `fly ssh console` with eval
4. **Email provider required** — prod raises without `POSTMARK_API_KEY` or `RESEND_API_KEY`
5. **Migrations auto-run** — `migrate_and_start` script handles this on deploy
6. **fly.toml has hardcoded app name** — either fork fly.toml or use `--app` flag

## Open Questions

1. Should each operator get a separate Neon project, or a branch within one project?
   → Separate project for isolation. Branches are for dev/staging.
2. How to handle fly.toml app name for multiple operators?
   → Use `fly deploy --app <name>` flag. Don't fork fly.toml.
3. Content seeding — can it run via release eval?
   → Seeder module exists but only as Mix task. Need `Haul.Content.Seeder.seed!/1` via eval.
