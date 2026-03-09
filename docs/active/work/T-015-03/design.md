# T-015-03 Design: Marketing Landing Page

## Decision: How to route bare domain to marketing page

### Option A: Branch in PageController based on host
- Check `conn.host == base_domain` in `home/2`, render different template
- Simple, no plug changes
- **Rejected:** Mixes routing concern into controller logic. In dev, `base_domain` = "localhost" which is also the fallback host, making it hard to test operator pages on localhost.

### Option B: Add `:is_platform_host` assign in TenantResolver
- TenantResolver already knows when subdomain is nil and host matches base_domain
- Add `assign(:is_platform_host, true)` in the fallback path when host == base_domain
- Controller checks `conn.assigns.is_platform_host` to decide which template
- **Rejected:** Slightly better but still branches in the same controller action.

### Option C: Separate controller action, conditional in router
- Phoenix doesn't support conditional routing natively
- Would need a plug that redirects or halts, adding complexity
- **Rejected:** Over-engineered for this use case.

### Option D (chosen): Add assign in TenantResolver + separate controller action
- TenantResolver adds `assign(:is_platform_host, true/false)` based on whether the host IS the bare domain (no subdomain extracted, host matches base_domain or is "localhost" in dev)
- PageController `home/2` checks `conn.assigns.is_platform_host`:
  - If true → call `marketing(conn, params)` which renders `:marketing` template
  - If false → existing operator landing page logic
- Marketing template is a new file alongside `home.html.heex`

**Rationale:** Minimal changes. TenantResolver already has the context to know if this is the bare domain. The controller dispatches to the right template. No router changes needed.

**Dev/test behavior:** In dev on `localhost:4000`, base_domain = "localhost", host = "localhost" → `is_platform_host = true` → marketing page. To see operator page, use `joes.localhost:4000`. This is the correct behavior — the bare domain IS the platform domain.

## Marketing page content design

### Sections (top to bottom)
1. **Nav bar** — Logo ("Haul") + CTA button ("Get Started" → /app/signup)
2. **Hero** — "Your hauling business online in 2 minutes" + subtext + primary CTA
3. **Features** — 6 cards: website, booking, notifications, print flyers, QR codes, mobile-ready
4. **How it works** — 3 steps: Sign up, customize, launch
5. **Pricing** — 4-tier table (Starter free, Pro $29, Business $79, Dedicated $149)
6. **Demo** — Link to live demo operator site
7. **Footer** — Copyright, links

### Design tokens
Same system: dark bg, Oswald headings, Source Sans 3 body, grayscale, flat (no border-radius). Use existing CSS properties. Heroicons for feature icons.

### Responsive
- Mobile-first. Feature grid: 1 col → 2 col → 3 col
- Pricing: stacked on mobile, 4-col on desktop
- Nav: simple, no hamburger needed (just logo + single CTA)

### No JavaScript required
Server-rendered, static content. No LiveView needed.
