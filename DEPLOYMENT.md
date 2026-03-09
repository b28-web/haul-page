# Deployment

## Architecture

```
[Browser] → [Fly.io CDN/TLS] → [Phoenix on Fly VM] → [Neon Postgres]
                                        ↓
                                 [Fly Tigris S3]
                                 (photos, tickets)
```

Single Fly.io VM per operator. Scale-to-zero when idle. Wakes on first request (~2–3s cold start).

## Production deploy

```bash
just deploy
```

This runs `flyctl deploy --remote-only` — builds the Docker image on Fly's remote builders and deploys it. Migrations run automatically on startup.

### Prerequisites

1. **Fly.io CLI**: `brew install flyctl`
2. **Authenticated**: `flyctl auth login`
3. **App exists**: `flyctl apps create haul-page` (one-time)
4. **Secrets set**: see below

### Required secrets

```bash
flyctl secrets set \
  DATABASE_URL="postgresql://user:pass@ep-xxx.aws.neon.tech/haul?sslmode=require" \
  SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  PHX_HOST="yourdomain.com" \
  OPERATOR_NAME="Your Business Name" \
  OPERATOR_PHONE="5551234567" \
  OPERATOR_EMAIL="info@yourdomain.com" \
  OPERATOR_SERVICE_AREA="Anytown, USA & Surrounding Areas" \
  OPERATOR_TAGLINE="Fast, honest, affordable."
```

### Custom domain

```bash
flyctl certs create yourdomain.com
# Then point your DNS:
# CNAME yourdomain.com → haul-page.fly.dev
```

Fly handles TLS certificate provisioning automatically.

## Local deploy (test the release locally)

Build and run the production release on your machine to verify everything works before deploying.

```bash
# 1. Build the Docker image
docker build -t haul-page .

# 2. Run with a local Postgres
docker run --rm \
  -p 4000:4000 \
  -e DATABASE_URL="postgresql://postgres:postgres@host.docker.internal:5432/haul_prod" \
  -e SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  -e PHX_HOST="localhost" \
  -e OPERATOR_NAME="Test Hauling" \
  -e OPERATOR_PHONE="5551234567" \
  haul-page

# 3. Visit http://localhost:4000
```

Or without Docker, using a native release:

```bash
# Build
MIX_ENV=prod mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release

# Run
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/haul_prod" \
SECRET_KEY_BASE="$(mix phx.gen.secret)" \
PHX_HOST="localhost" \
OPERATOR_NAME="Test Hauling" \
OPERATOR_PHONE="5551234567" \
_build/prod/rel/haul/bin/haul start
```

## Database

### Neon Postgres setup

1. Create a project at [neon.tech](https://neon.tech)
2. Copy the pooled connection string (ends in `-pooler.aws.neon.tech`)
3. Set as `DATABASE_URL` in Fly secrets

Neon scales to zero automatically. Free tier: 0.5GB storage, 100 CU-hours/month.

### Migrations

Migrations run automatically on every deploy via the release startup script. To run manually:

```bash
# Production (via Fly SSH)
flyctl ssh console -C "/app/bin/haul eval 'Haul.Release.migrate()'"

# Local
mix ecto.migrate
```

### Rollback

```bash
flyctl ssh console -C "/app/bin/haul eval 'Haul.Release.rollback(Haul.Repo, 20240101000000)'"
```

## Monitoring

- **Phoenix LiveDashboard**: `/dev/dashboard` (dev only, auth-gated in prod)
- **Fly.io dashboard**: `flyctl dashboard`
- **Logs**: `flyctl logs`
- **SSH**: `flyctl ssh console`

## Cost

| Component | Dev | Production |
|-----------|-----|------------|
| Fly.io VM | free tier | ~$4–8/mo (scale-to-zero) |
| Neon Postgres | free tier | ~$5–15/mo |
| Fly Tigris | free tier | ~$0–2/mo |
| **Total** | **$0** | **~$10–25/mo** |
