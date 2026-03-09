# haul-page — Specification

## What this is

A single deployable website for one junk removal / hauling / handyman operator.
The site serves two purposes at once:

1. **Web presence** — a dark, minimal landing page with contact info, services, and an online booking entry point.
2. **Print flyer** — the same page prints cleanly on paper with low ink cost (dark text on white via `@media print`, or hand the customer the URL).

This repo is the first tangible piece of the broader HaulOS platform. It produces the public-facing surface that customers see — everything from "I found this company" to "I submitted a booking request." The operator-facing app (dispatch board, crew tools, billing) lives behind authentication on the same Phoenix instance.

## User story

> I run a small junk removal business with 1–3 trucks. I need a website that:
>
> - Looks professional but isn't bloated
> - Loads instantly on any phone
> - Lets customers see what I do, where I serve, and how to reach me
> - Has an online booking form so leads come in while I'm on a job
> - Costs nearly nothing to host month-to-month
> - I can hand someone a URL that also works as a flyer if they print it

## Deploy / product intention

### Stack

| Layer | Choice | Why |
|-------|--------|-----|
| App server | Phoenix (Elixir) on Fly.io | Single shared-CPU VM, ~$4–8/mo. Scales to zero. Same runtime serves the landing page, booking form, and (later) the full operator app. |
| Database | Neon Postgres | Free tier for early use, serverless scale-to-zero, ~$5–15/mo under load. |
| Assets | Fly Tigris (S3-compatible) | Job photos, weight tickets. Co-located with the app. Free egress within Fly. |
| Domain/TLS | Fly.io | Handles TLS termination and anycast routing. Operator brings their own domain. |

### Cost target

**< $15/month** for a single operator with low-to-moderate traffic. The free tiers of Neon and Fly cover dev/staging entirely.

### What ships first

A single Phoenix app that serves:

1. **`/`** — The public landing page / printable poster. Four sections stacked vertically:
   - **Hero**: "Licensed & Insured · Serving Your Area" eyebrow, giant "Junk Hauling" headline (Oswald), "& Handyman Services" subtitle, tagline, phone number as oversized tel: link, email + location
   - **Services grid**: 2×3 (mobile 2-col, desktop 3-col). Icons + title + one-line description. Junk Removal, Cleanouts, Yard Waste, Repairs, Assembly, Moving Help.
   - **Why Hire Us**: dash-prefixed list, 2-col on desktop. Same-day availability, upfront pricing, licensed/insured, we clean up, locally owned, free estimates.
   - **Footer CTA**: "Ready to Get Started?" with phone button + "Print as Poster" button (screen only). Tear-off strip with 8 vertical tabs prints at bottom (print only) — each tab has business name, "10% OFF", and phone number.
   - **Print stylesheet**: white bg, black text, strip backgrounds, full-width, Oswald for headings at 42pt/22pt, Source Sans 3 for body at 11pt, 0.3in page margins, `.no-print` hides interactive elements.
   - **Typography**: Oswald (display/headings, uppercase, tracked), Source Sans 3 (body). Loaded from Google Fonts. Dark theme uses `0 0% 6%` background, `0 0% 92%` foreground (pure grayscale, no warmth — monochrome).
   - **No JavaScript required** — page works with JS disabled.

2. **`/scan`** — "Scan to Schedule" page. Reached via QR code on printed materials (truck wraps, flyers, door hangers). Dual purpose:
   - **Schedule**: CTA to book / call, streamlined for someone who just scanned a code and wants to act now.
   - **Social proof**: Before/after photo gallery, customer endorsements/testimonials. Builds trust for someone who's on the fence after seeing the truck or flyer.
   - This is a LiveView page (needs dynamic gallery content). The QR code URL is the operator's domain + `/scan`.

3. **`/book`** — Online booking form (LiveView). Customer submits: name, phone, address, item description, load photos (mobile camera capture), preferred dates. Creates a Job in `:lead` state. Owner gets notified via SMS/email.

4. **Auth + operator app** — Behind `/app` (later). Not in the first deploy, but the Phoenix app is structured to support it from day one via Ash resources and AshAuthentication.

### What this is NOT

- Not a static site generator. The booking form needs server state and real-time validation.
- Not a SaaS control plane (yet). This repo deploys one instance for one operator. Multi-tenancy comes later when the operator app matures.
- Not a React/SPA. The public pages are server-rendered HTML. LiveView handles interactivity where needed (booking form). No JS bundle for the landing page.

### Design principles

- **Minimal by default.** Every element earns its place. The mockup is four sections on a dark background with zero decoration — no gradients, no shadows, no borders, no images. Pure typography and spacing.
- **Print-aware.** `@media print` flips to light background, dark text, hides interactive elements. The URL is the flyer.
- **Mobile-first.** Most customers find this on their phone. Large touch targets, fast load, no layout shifts.
- **Progressive enhancement.** Landing page works without JS. Booking form uses LiveView (WebSocket upgrade). Crew app (later) adds PWA capabilities.
- **Operator-configurable.** Business name, phone, services, service area, colors — all driven by config, not code changes. One repo, many operators (via separate deploys with different config).

---

## Monorepo structure

This is a single Phoenix app, not an umbrella and not a polyglot monorepo with separately-deployed services. Everything ships as one Elixir release. The question is how to organize the code inside that constraint.

### Layout

```
haul-page/
├── config/                  # Elixir app config (dev/test/prod/runtime)
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   ├── prod.exs
│   └── runtime.exs          # Env vars: DATABASE_URL, operator config
│
├── lib/
│   ├── haul/                 # Business logic — Ash domains + resources
│   │   ├── accounts/         # Company, User (AshAuthentication)
│   │   ├── operations/       # Job, Quote, QuoteLineItem, Truck, etc.
│   │   ├── disposal/         # DisposalFacility, DisposalRun
│   │   └── billing/          # Invoice, Payment, Ledger
│   │
│   ├── haul_web/             # Phoenix web layer
│   │   ├── components/       # Phoenix function components (shared)
│   │   ├── layouts/          # Root + app layouts (HEEx)
│   │   ├── controllers/      # Traditional controllers (landing page)
│   │   ├── live/             # LiveView modules
│   │   │   ├── booking_live.ex
│   │   │   ├── dispatch_live.ex    # (later)
│   │   │   └── crew_live.ex        # (later)
│   │   ├── router.ex
│   │   ├── endpoint.ex
│   │   └── telemetry.ex
│   │
│   ├── haul.ex               # Application entry point
│   └── haul_web.ex            # Web module macros
│
├── assets/                   # Frontend source — Phoenix asset pipeline
│   ├── css/
│   │   ├── app.css           # Tailwind entry point
│   │   └── print.css         # @media print overrides
│   ├── js/
│   │   └── app.js            # LiveView JS hooks (minimal)
│   ├── vendor/               # Vendored libs (topbar, etc.)
│   └── static/               # Files copied verbatim to priv/static
│       └── fonts/
│           └── Oswald + Source Sans 3.woff2
│
├── priv/
│   ├── static/               # Build output (digested by phx.digest)
│   ├── repo/
│   │   └── migrations/       # Ecto/Ash migrations
│   └── gettext/
│
├── test/
│   ├── haul/                 # Domain logic tests
│   ├── haul_web/             # Controller + LiveView tests
│   └── support/
│
├── docs/
│   ├── knowledge/            # Specs, decisions, reference
│   └── active/               # Tickets, stories, work artifacts
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── mix.exs                   # Elixir deps + project config
├── mix.lock
├── fly.toml                  # Fly.io deploy config
├── Dockerfile                # Multi-stage release build
├── .formatter.exs
├── .credo.exs
└── CLAUDE.md
```

### Why not an umbrella?

Phoenix umbrellas (`apps/haul`, `apps/haul_web`) add indirection — separate Mix projects, separate deps, separate configs — for a benefit that only matters when you have teams that need independent compilation boundaries. This is a single-operator product built by a small team. One `mix.exs`, one `config/`, one test suite. If the domains outgrow this, Ash's domain boundaries (`Haul.Accounts`, `Haul.Operations`, etc.) provide the modularity that matters — they enforce cross-domain interfaces at the resource level, which is stronger than umbrella app separation anyway.

### Why not a separate frontend repo/workspace?

The landing page is server-rendered HEEx. The booking form is LiveView. There is no React app, no separate JS build, no npm workspace needed. Phoenix's built-in asset pipeline (esbuild for JS, tailwind CLI for CSS) handles everything:

- `esbuild` bundles `assets/js/app.js` → `priv/static/assets/app.js` (LiveView hooks, topbar, not much else)
- `tailwind` compiles `assets/css/app.css` → `priv/static/assets/app.css`
- Static files in `assets/static/` (fonts, favicon) are copied to `priv/static/`

No node_modules. No pnpm workspace. The esbuild and tailwind binaries are fetched as standalone executables by their respective Mix tasks — they don't need Node installed in production or CI.

If a future phase adds a heavier JS component (Stripe Elements embed, drag-and-drop dispatch board hooks), it stays in `assets/js/` with esbuild handling the bundle. The threshold for adding a Node build step is "esbuild can't do it" — and for this project, that threshold is unlikely to be crossed.

### Operator configuration

The "one repo, many operators" model works via runtime config, not code forks:

```elixir
# config/runtime.exs
config :haul, :operator,
  business_name: System.get_env("OPERATOR_NAME", "Junk Hauling"),
  phone: System.get_env("OPERATOR_PHONE"),
  service_area: System.get_env("OPERATOR_SERVICE_AREA"),
  primary_color: System.get_env("OPERATOR_COLOR", "#1b1b1b"),
  tagline: System.get_env("OPERATOR_TAGLINE")
```

Each operator gets their own Fly.io app with their own env vars. Same Docker image, different config. This avoids multi-tenancy complexity until the SaaS model is validated.

---

## Deploy strategy

### Build: Multi-stage Dockerfile

Phoenix has a well-established release Dockerfile pattern (generated by `mix phx.gen.release --docker`):

1. **Build stage** — Elixir + Erlang image, compile deps, compile app, `mix assets.deploy` (runs esbuild + tailwind + phx.digest), `mix release`
2. **Runtime stage** — Minimal Debian image, copy the release, run it. No Elixir/Erlang/Node installed at runtime. Final image ~60–80MB.

The release is a self-contained OTP release with embedded ERTS. It boots fast and uses minimal memory.

### Target: Fly.io

```toml
# fly.toml
app = "haul-page"
primary_region = "sea"        # Seattle — adjust per operator

[build]
  dockerfile = "Dockerfile"

[env]
  PHX_HOST = "example.com"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"     # Scale to zero when idle
  auto_start_machines = true      # Wake on request
  min_machines_running = 0

[http_service.checks]
  grace_period = "10s"
  interval = "30s"
  method = "GET"
  path = "/healthz"
  timeout = "5s"
```

Key decisions:
- **`auto_stop_machines = "stop"`** — The VM stops when there's no traffic. First request after idle takes ~2–3s to boot (Phoenix starts fast). This is the main cost saver — the operator isn't paying for a VM at 3am.
- **`min_machines_running = 0`** — Allows full scale-to-zero. For an operator who wants instant response, set to 1 (~$4/mo).
- **Single region** — No multi-region for a local junk removal business. Pick the region closest to the operator's market.

### Database: Neon Postgres

Connection via `DATABASE_URL` env var set in Fly secrets:

```bash
fly secrets set DATABASE_URL="postgresql://user:pass@ep-xxx.us-west-2.aws.neon.tech/haul?sslmode=require"
```

Neon's connection pooler handles the serverless wake-up. The Phoenix app uses `Ecto.Adapters.Postgres` pointed at Neon's pooled endpoint. No PgBouncer needed — Neon provides it.

Migrations run on deploy via a release command in the Dockerfile:

```dockerfile
CMD ["/app/bin/migrate_and_start"]
```

Where `migrate_and_start` is a shell script that runs `bin/haul eval "Haul.Release.migrate()"` then starts the app.

---

## CI/CD

### GitHub Actions workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  MIX_ENV: test
  ELIXIR_VERSION: "1.19"
  OTP_VERSION: "28"

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        ports: ["5432:5432"]
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{ env.ELIXIR_VERSION }}
          otp-version: ${{ env.OTP_VERSION }}

      - uses: actions/cache@v4
        with:
          path: |
            deps
            _build
          key: mix-${{ runner.os }}-${{ hashFiles('mix.lock') }}

      - run: mix deps.get
      - run: mix compile --warnings-as-errors
      - run: mix test

  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{ env.ELIXIR_VERSION }}
          otp-version: ${{ env.OTP_VERSION }}

      - uses: actions/cache@v4
        with:
          path: |
            deps
            _build
          key: mix-${{ runner.os }}-${{ hashFiles('mix.lock') }}

      - run: mix deps.get
      - run: mix format --check-formatted
      - run: mix credo --strict
      - run: mix dialyzer

  deploy:
    needs: [test, quality]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: superfly/flyctl-actions/setup-flyctl@master

      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Pipeline design

Three jobs, two gate the third:

1. **`test`** — Spins up Postgres 16 as a service, runs `mix test`. This validates Ash resources, migrations, and LiveView tests against a real database.
2. **`quality`** — Runs in parallel with test. `mix format --check-formatted` + `mix credo --strict` + `mix dialyzer`. Dialyzer catches type errors at compile time — especially valuable with Ash resources where action signatures are typed.
3. **`deploy`** — Only on `main` push, only if both test and quality pass. Uses `flyctl deploy --remote-only` which builds the Docker image on Fly's remote builders and deploys it. No Docker build in CI — saves minutes and avoids CI runner disk pressure.

### What's NOT in CI

- **No migration generation check yet.** The HaulOS spec mentions `mix ash_postgres.generate_migrations` check in CI. This is valuable but adds complexity before there are any resources. Add it when the first Ash resource lands.
- **No staging environment.** Single operator, single deploy. If a staging environment is needed, it's a second Fly app (`haul-page-staging`) with its own Neon branch — Neon's branching makes this free.
- **No E2E browser tests.** Wallaby/Playwright could test the booking flow end-to-end. Worth adding at Phase 1 when the booking form exists. Not before.

---

## External services — buy, don't build

These capabilities are hard to build correctly, carry regulatory or deliverability risk, or require domain expertise that isn't core to the product. Use SaaS for all of them.

### Must-have (required before or at launch)

| Capability | Service | Why SaaS |
|---|---|---|
| **SMS notifications** | Twilio | Job submission alerts, state-change notifications to operator. Carrier regulations, deliverability, number provisioning — not worth touching. |
| **Transactional email** | Postmark or Resend | Magic-link auth (AshAuthentication), booking confirmations, operator alerts. Deliverability and spam reputation are someone else's problem. |
| **Payment processing** | Stripe | Operator SaaS subscription fees and (later) customer job payments. PCI compliance, fraud detection, chargebacks — non-negotiable outsource. Stripe Elements embeds in LiveView via JS hooks. |
| **Object storage** | Fly Tigris (S3-compatible) | Already chosen. Job photos, gallery images. Co-located with app on Fly. |

### High-value (add early, saves significant effort)

| Capability | Service | Why SaaS |
|---|---|---|
| **Address autocomplete** | Google Places API or Mapbox | Booking form address field. Reduces bad input, improves mobile UX. Google Places is standard for US addresses; Mapbox is cheaper at scale. |
| **Error monitoring** | Sentry or Honeybadger | Centralized exception tracking across per-operator deploys. Honeybadger has first-class Elixir/Plug integration. |
| **Uptime monitoring** | BetterStack or Fly health checks | Each operator deploy needs a heartbeat. BetterStack provides status pages; Fly's built-in checks cover basic liveness. |

### Worth it at scale

| Capability | Service | Why SaaS |
|---|---|---|
| **Analytics** | Plausible or Fathom | Privacy-respecting, lightweight. Operators want booking conversion rates. Self-hosting Plausible is possible but adds ops burden. |
| **Image processing / CDN** | Imgproxy or Cloudflare Images | Gallery before/after photos and job uploads need resizing and optimization. Don't write a thumbnail pipeline. |

### Use a library, not a service

| Capability | Library | Notes |
|---|---|---|
| **QR code generation** | `eqrcode` (Elixir) | `/scan` page QR codes. Pure computation, no external dependency needed. |
| **Markdown rendering** | MDEx | Content system already specifies this. Compile-time HTML caching. |

### What NOT to build

Even if it seems simple at first:

- **Email delivery infrastructure** — SMTP reputation takes months to establish. One misconfiguration and all operator emails land in spam.
- **SMS gateway** — Carrier filtering, 10DLC registration, opt-out compliance. Twilio handles all of it.
- **Payment/billing system** — PCI-DSS compliance alone costs more than the entire product. Stripe's fee is the cost of not thinking about it.
- **Address validation** — USPS data licensing, international formats, geocoding accuracy. Google/Mapbox have billion-dollar datasets.
- **Error aggregation** — Grouping, deduplication, alerting, source maps. Mature products exist for $0–26/mo.
