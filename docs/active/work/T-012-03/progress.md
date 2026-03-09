# T-012-03 Progress: Wildcard DNS

## Completed

### Step 1: fly.toml env vars ✓
- Changed `PHX_HOST` from `haul-page.fly.dev` to `haulpage.com`
- Added `BASE_DOMAIN = "haulpage.com"`

### Step 2: check_origin config in runtime.exs ✓
- Added `check_origin` configuration in the `BASE_DOMAIN` block
- Wildcard pattern `//*.haulpage.com` allows all subdomain WebSocket connections
- Bare domain pattern `//haulpage.com` allows the platform root

### Step 3: Onboarding runbook documentation ✓
- Added "SaaS Platform DNS (One-Time Setup)" section to `docs/knowledge/operator-onboarding.md`
- Covers: getting Fly IPs, DNS records (A/AAAA for bare + wildcard), Fly certificates, env vars, verification

### Step 4: Tests ✓
- All 14 tenant resolver tests pass
- Full suite: 250 tests, 1 failure (pre-existing flaky QR controller test — passes in isolation)

## Deviations from Plan

None. The implementation followed the plan exactly.
