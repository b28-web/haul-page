# Operator Onboarding Runbook

> **Estimated time:** 20–30 minutes for someone following these steps.
>
> This is the manual process. For the automated version, see T-014-01 (`mix haul.onboard`).

## Prerequisites

**Tools:**
- `flyctl` — [Install](https://fly.io/docs/flyctl/install/): `brew install flyctl`
- A Neon account at [neon.tech](https://neon.tech)
- An email provider account (Postmark recommended, or Resend)

**Accounts:**
- Fly.io — `fly auth login`
- Neon — logged in at console.neon.tech

**Gather from the operator:**
- Business name, phone number, email
- Tagline (one-liner for landing page)
- Service area (e.g., "Portland, OR & Surrounding Areas")
- Custom domain (if any)
- Choose an operator slug: lowercase, hyphens only (e.g., `acme-hauling`)

---

## Steps

### 1. Create the Fly app

```bash
fly apps create haul-<OPERATOR_SLUG>
```

Verify:
```bash
fly apps list | grep haul-<OPERATOR_SLUG>
```

### 2. Create the Neon database

1. Go to [console.neon.tech](https://console.neon.tech) → **New Project**
2. Project name: `haul-<OPERATOR_SLUG>`
3. Region: `us-east-1` (matches Fly `iad` region)
4. Postgres version: 16+
5. Copy the **pooled connection string** — it looks like:
   ```
   postgresql://user:pass@ep-xxx-pooler.us-east-1.aws.neon.tech/neondb?sslmode=require
   ```

### 3. Set secrets on Fly

Generate a secret key:
```bash
SECRET_KEY=$(openssl rand -base64 48)
```

Set all required secrets:
```bash
fly secrets set \
  --app haul-<OPERATOR_SLUG> \
  DATABASE_URL="<NEON_POOLED_CONNECTION_STRING>" \
  SECRET_KEY_BASE="$SECRET_KEY" \
  PHX_HOST="haul-<OPERATOR_SLUG>.fly.dev" \
  OPERATOR_BUSINESS_NAME="<BUSINESS_NAME>" \
  OPERATOR_PHONE="<PHONE_NUMBER>" \
  OPERATOR_EMAIL="<EMAIL_ADDRESS>" \
  OPERATOR_TAGLINE="<TAGLINE>" \
  OPERATOR_SERVICE_AREA="<SERVICE_AREA>" \
  POSTMARK_API_KEY="<POSTMARK_SERVER_TOKEN>"
```

> **Note:** Use `RESEND_API_KEY` instead of `POSTMARK_API_KEY` if using Resend.

Verify:
```bash
fly secrets list --app haul-<OPERATOR_SLUG>
```

You should see all secret names listed (values are hidden).

### 4. Deploy

```bash
fly deploy --app haul-<OPERATOR_SLUG> --remote-only
```

This builds the Docker image on Fly's remote builders and deploys it. The `migrate_and_start` script runs migrations automatically on startup.

Verify the deploy succeeded:
```bash
fly status --app haul-<OPERATOR_SLUG>
```

You should see one machine in `started` or `stopped` state (scale-to-zero may stop it if no traffic).

### 5. Verify migrations ran

Migrations run automatically via the release startup script. To confirm:
```bash
fly logs --app haul-<OPERATOR_SLUG> | grep -i migrat
```

You should see log lines indicating migrations ran successfully. If you need to run them manually:
```bash
fly ssh console --app haul-<OPERATOR_SLUG> -C "/app/bin/haul eval 'Haul.Release.migrate()'"
```

### 6. Create company and seed content

Create the operator's company (this provisions the tenant schema):
```bash
fly ssh console --app haul-<OPERATOR_SLUG> -C "/app/bin/haul eval '
  Haul.Accounts.Company
  |> Ash.Changeset.for_create(:create_company, %{
    name: \"<BUSINESS_NAME>\",
    slug: \"<OPERATOR_SLUG>\"
  })
  |> Ash.create!()
'"
```

Seed the default content (services, gallery items, endorsements, site config):
```bash
fly ssh console --app haul-<OPERATOR_SLUG> -C "/app/bin/haul eval '
  companies = Ash.read!(Haul.Accounts.Company)
  for c <- companies do
    tenant = Haul.Accounts.Changes.ProvisionTenant.tenant_schema(c.slug)
    Haul.Content.Seeder.seed!(tenant)
  end
'"
```

Verify content was seeded:
```bash
fly ssh console --app haul-<OPERATOR_SLUG> -C "/app/bin/haul eval '
  [c] = Ash.read!(Haul.Accounts.Company)
  tenant = Haul.Accounts.Changes.ProvisionTenant.tenant_schema(c.slug)
  services = Ash.read!(Haul.Content.Service, tenant: tenant)
  IO.puts(\"Services: #{length(services)}\")
'"
```

### 7. Add custom domain (optional)

If the operator has their own domain:

```bash
fly certs add <DOMAIN> --app haul-<OPERATOR_SLUG>
```

Then configure DNS — add a CNAME record:
```
<DOMAIN>  CNAME  haul-<OPERATOR_SLUG>.fly.dev
```

Verify certificate provisioning:
```bash
fly certs show <DOMAIN> --app haul-<OPERATOR_SLUG>
```

Wait until the certificate status shows as "Ready". This usually takes 1-5 minutes.

Update the PHX_HOST secret to match the custom domain:
```bash
fly secrets set --app haul-<OPERATOR_SLUG> PHX_HOST="<DOMAIN>"
```

### 8. Verify everything works

**Health check:**
```bash
curl -s https://haul-<OPERATOR_SLUG>.fly.dev/healthz
# Expected: ok
```

**Landing page:** Open `https://haul-<OPERATOR_SLUG>.fly.dev` in a browser.
- Business name appears in the header
- Phone number is visible
- Services section shows seeded services
- Dark theme, Oswald headings

**Booking form:** Navigate to `https://haul-<OPERATOR_SLUG>.fly.dev/book`.
- Form renders with all fields
- Submit creates a job (check logs: `fly logs --app haul-<OPERATOR_SLUG>`)

**Print view:** Open the landing page and `Ctrl+P` / `Cmd+P`.
- White background, black text
- Coupon tear-off strip at the bottom

---

## Environment Variable Reference

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Postgres connection (pooled, SSL) | `postgresql://user:pass@ep-xxx-pooler.us-east-1.aws.neon.tech/neondb?sslmode=require` |
| `SECRET_KEY_BASE` | Cookie/session signing (64+ chars) | Output of `openssl rand -base64 48` |
| `PHX_HOST` | Public hostname for URL generation | `acmehauling.com` or `haul-acme.fly.dev` |
| `POSTMARK_API_KEY` | Email delivery (Postmark) | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `RESEND_API_KEY` | Email delivery (alternative to Postmark) | `re_xxxxxxxxxx` |

> One of `POSTMARK_API_KEY` or `RESEND_API_KEY` is required. The app will not start without an email provider.

### Operator Identity

| Variable | Description | Example |
|----------|-------------|---------|
| `OPERATOR_BUSINESS_NAME` | Displayed on landing page, emails | `Acme Hauling` |
| `OPERATOR_PHONE` | Contact number | `5551234567` |
| `OPERATOR_EMAIL` | Notification recipient | `info@acmehauling.com` |
| `OPERATOR_TAGLINE` | Landing page subtitle | `Fast, honest, affordable.` |
| `OPERATOR_SERVICE_AREA` | Geographic coverage | `Portland, OR & Surrounding Areas` |
| `OPERATOR_COUPON_TEXT` | Print coupon text (optional) | `$25 OFF YOUR FIRST HAUL` |

### Optional Integrations

| Variable | Description | Enables |
|----------|-------------|---------|
| `STRIPE_SECRET_KEY` | Stripe API key | Payment processing at `/pay/:job_id` |
| `STRIPE_PUBLISHABLE_KEY` | Stripe client key | Payment Element UI |
| `STRIPE_WEBHOOK_SECRET` | Webhook signature verification | `payment_intent.succeeded` handling |
| `TWILIO_ACCOUNT_SID` | Twilio account | SMS booking notifications |
| `TWILIO_AUTH_TOKEN` | Twilio auth (required with SID) | SMS sending |
| `TWILIO_FROM_NUMBER` | SMS sender number | `+15551234567` |
| `GOOGLE_PLACES_API_KEY` | Google Places API | Address autocomplete on booking form |
| `STORAGE_BUCKET` | Fly Tigris bucket name | Photo uploads |
| `AWS_ACCESS_KEY_ID` | Tigris access key (with STORAGE_BUCKET) | S3-compatible storage |
| `AWS_SECRET_ACCESS_KEY` | Tigris secret (with STORAGE_BUCKET) | S3-compatible storage |

### Infrastructure

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTP port | `4000` |
| `POOL_SIZE` | Database connection pool | `10` |
| `ECTO_IPV6` | Enable IPv6 for DB connection | unset |
| `DNS_CLUSTER_QUERY` | Multi-machine clustering | unset |

---

## Rollback

### Roll back to previous release

List recent releases:
```bash
fly releases --app haul-<OPERATOR_SLUG>
```

Deploy a previous image:
```bash
fly deploy --app haul-<OPERATOR_SLUG> --image <PREVIOUS_IMAGE_REF>
```

### Roll back a migration

```bash
fly ssh console --app haul-<OPERATOR_SLUG> -C "/app/bin/haul eval 'Haul.Release.rollback(Haul.Repo, <MIGRATION_VERSION>)'"
```

Replace `<MIGRATION_VERSION>` with the timestamp of the migration to roll back to (e.g., `20240615120000`).

---

## Full Teardown

If onboarding failed and you need to start over:

```bash
# 1. Destroy the Fly app (removes VM, secrets, certificates)
fly apps destroy haul-<OPERATOR_SLUG> --yes

# 2. Delete the Neon project
# Go to console.neon.tech → project → Settings → Delete Project
# Or via CLI: neonctl projects delete haul-<OPERATOR_SLUG>

# 3. Remove DNS records (if custom domain was configured)
# Remove the CNAME record from your DNS provider
```

---

## SaaS Platform DNS (One-Time Setup)

> This section documents the wildcard DNS setup for the shared `haulpage.com` platform domain. This is done **once** for the platform, not per operator. New operators get `slug.haulpage.com` automatically.

### 1. Get Fly app IPs

```bash
fly ips list --app haul-page
```

Note the IPv4 and IPv6 addresses (e.g., `66.241.124.x` and `2a09:8280:1::...`).

### 2. Configure DNS records

At your DNS registrar for `haulpage.com`, add these records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| `A` | `@` (bare domain) | Fly IPv4 address | 300 |
| `AAAA` | `@` (bare domain) | Fly IPv6 address | 300 |
| `A` | `*` (wildcard) | Fly IPv4 address | 300 |
| `AAAA` | `*` (wildcard) | Fly IPv6 address | 300 |

### 3. Add certificates on Fly

```bash
fly certs add "haulpage.com" --app haul-page
fly certs add "*.haulpage.com" --app haul-page
```

Verify certificate status:
```bash
fly certs list --app haul-page
```

Both should show status "Ready" within a few minutes. Fly handles automatic renewal.

### 4. Set environment variables

```bash
fly secrets set --app haul-page \
  BASE_DOMAIN="haulpage.com" \
  PHX_HOST="haulpage.com"
```

> `BASE_DOMAIN` is used by TenantResolver to extract subdomains. `PHX_HOST` controls URL generation.

### 5. Verify

```bash
# Bare domain serves the app
curl -s https://haulpage.com/healthz
# Expected: ok

# Any subdomain serves the app
curl -s https://test.haulpage.com/healthz
# Expected: ok

# Wildcard cert covers subdomains
curl -vI https://anything.haulpage.com 2>&1 | grep "subject:"
# Should show *.haulpage.com in the certificate
```

After this setup, creating a new Company with slug `acme` makes `acme.haulpage.com` work immediately — no DNS changes needed.

---

## Troubleshooting

### Deploy fails with "no machines"

The app was created but no machine was provisioned. This can happen if the first deploy fails partway through.

```bash
fly machine list --app haul-<OPERATOR_SLUG>
# If empty, the deploy didn't create a machine. Re-run:
fly deploy --app haul-<OPERATOR_SLUG> --remote-only
```

### Health check fails (app won't start)

Check logs for startup errors:
```bash
fly logs --app haul-<OPERATOR_SLUG>
```

Common causes:
- **Missing secret:** `SECRET_KEY_BASE is missing` or `DATABASE_URL is missing` → set the missing secret
- **Database unreachable:** SSL or connection errors → verify `DATABASE_URL` is the pooled string with `?sslmode=require`
- **Email provider missing:** `No email adapter configured` → set `POSTMARK_API_KEY` or `RESEND_API_KEY`

### Content not showing on landing page

The company and content haven't been seeded. Run Step 6 again.

Verify the company exists:
```bash
fly ssh console --app haul-<OPERATOR_SLUG> -C "/app/bin/haul eval '
  IO.inspect(Ash.read!(Haul.Accounts.Company))
'"
```

### Custom domain shows SSL error

Certificate provisioning takes 1-5 minutes. Check status:
```bash
fly certs show <DOMAIN> --app haul-<OPERATOR_SLUG>
```

If it's stuck, verify the DNS CNAME is correctly pointed at `haul-<OPERATOR_SLUG>.fly.dev`.

---

## Cost Estimate (Per Operator)

| Component | Monthly Cost |
|-----------|-------------|
| Fly.io VM (shared-cpu-1x, 256MB, scale-to-zero) | $4–8 |
| Neon Postgres (production tier) | $5–15 |
| Fly Tigris S3 (photos) | $0–2 |
| Postmark (email, 100 emails/mo free tier) | $0 |
| **Total** | **$10–25** |

Low-traffic operators with scale-to-zero will be at the lower end. Costs scale with traffic and storage usage.
