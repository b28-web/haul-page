# T-001-04 Research: Dockerfile

## Current State

### Project Structure
- **App name:** `:haul` (Elixir/Phoenix 1.8.5 + LiveView 1.1 + Ash 3.19)
- **Web server:** Bandit
- **Database:** PostgreSQL 16 (Ecto + AshPostgres)
- **Assets:** Tailwind 4.1.12 (standalone CLI) + esbuild 0.25.4 (standalone binary)
- **No Node.js** — both tailwind and esbuild are fetched as standalone binaries via Mix tasks

### Version Pins (mise.toml)
- Erlang/OTP: 28
- Elixir: 1.19
- These same versions are used in CI (`ci.yml` env vars)

### Asset Pipeline
- `mix assets.deploy` runs: `tailwind haul --minify`, `esbuild haul --minify`, `phx.digest`
- Tailwind input: `assets/css/app.css` → `priv/static/assets/css/app.css`
- esbuild input: `assets/js/app.js` → `priv/static/assets/js/`
- esbuild uses `--external:/fonts/*` and `--external:/images/*`
- Asset vendor dir: `assets/vendor/`

### Config Layout
- `config/config.exs` — compile-time config (esbuild/tailwind versions, endpoint defaults)
- `config/prod.exs` — compile-time prod (cache manifest, force_ssl, swoosh API client)
- `config/runtime.exs` — runtime config (DATABASE_URL, SECRET_KEY_BASE, PHX_HOST, PHX_SERVER, PORT)
- `PHX_SERVER=true` enables the server at boot

### Dependencies
- Heavy Ash ecosystem: ash, ash_postgres, ash_phoenix, ash_authentication, ash_state_machine, ash_oban, ash_double_entry, ash_money, ash_paper_trail, ash_archival
- ex_money / ex_cldr (requires locale data compilation)
- heroicons from GitHub (sparse checkout, compile: false)
- Dev/test only deps: phoenix_live_reload, credo, dialyxir, ex_machina, lazy_html

### Release Configuration
- No `rel/` directory exists yet — no custom release config, vm.args, or env.sh
- `mix phx.gen.release` would generate `rel/overlays/bin/server` and `rel/overlays/bin/migrate`
- The app uses `Haul.Application` as the OTP app module
- DNSCluster is configured (Fly.io clustering)

### CI Pipeline (T-001-03)
- Deploy job exists in ci.yml: uses `superfly/flyctl-actions/setup-flyctl` + `flyctl deploy --remote-only`
- `--remote-only` means Fly.io builds using the Dockerfile on their remote builders

### Existing Files
- No Dockerfile exists
- No .dockerignore exists
- `.gitignore` excludes `_build/`, `deps/`, `priv/static/assets/`, `priv/static/cache_manifest.json`

### Acceptance Criteria Review
1. Multi-stage: build (compile + assets + release) and runtime
2. Runtime: minimal Debian, no Elixir/Erlang/Node
3. Embedded ERTS in release
4. `bin/migrate_and_start` script
5. `docker build .` succeeds locally
6. Final image < 100MB

## Key Constraints
- Tailwind and esbuild binaries are platform-specific — must be fetched inside the Docker build for the correct architecture (linux/amd64 or linux/arm64)
- Ash and ex_cldr do compile-time codegen — need full `config/` available during compilation
- No node_modules or npm — asset build is purely Mix-driven
- `mix release` with `include_erts: true` (default) embeds ERTS
- Fly.io convention: Debian bookworm-slim for runtime
