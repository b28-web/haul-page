# haul-page

A website + booking system for junk removal operators. Dark, minimal, prints as a poster. Built with Phoenix + Ash, deployed on Fly.io for < $15/month.

## Pages

| Route | What | Tech |
|-------|------|------|
| `/` | Landing page + printable poster | Server-rendered HEEx |
| `/scan` | QR code landing — schedule CTA + before/after gallery | LiveView |
| `/book` | Online booking form — creates a lead | LiveView |

## Quick start

```
mise install           # Elixir 1.19 + Erlang/OTP 28
just dev               # deps, migrate, start server
```

Requires Postgres running locally (or set `DATABASE_URL`).

## Commands

```
just dev               # Start local development
just deploy            # Deploy to Fly.io
just status            # Show ticket DAG and progress
just work              # Launch lisa agent swarm
just llm               # Print repo context for LLM coders
```

## Stack

Elixir, Phoenix, Ash Framework, LiveView, Tailwind CSS, Neon Postgres, Fly.io.

See [docs/knowledge/specification.md](docs/knowledge/specification.md) for the full spec.

## Browser testing (agent QA)

Claude Code instances on this project get [Playwright MCP](https://github.com/microsoft/playwright-mcp) automatically via `.mcp.json`. This lets LLM agents test the running app in a real browser without human QA.

**How it works:**

1. Agent starts the Phoenix dev server (`mix phx.server` or `just dev`)
2. Agent uses Playwright MCP tools to navigate to `localhost:4000`, interact with pages, and verify behavior
3. Playwright operates on accessibility snapshots (structured data), not screenshots — works headless in CI and on dev machines

**Available to agents automatically** — no setup needed. The `.mcp.json` at project root configures Playwright MCP at project scope.

**For interactive dev sessions**, use `claude --chrome` to connect Claude Code to a visible Chrome window (requires the [Claude in Chrome extension](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn)).

### First-time setup

```
npx playwright install --with-deps chromium   # one-time browser binary install
```

## License

See [LICENSE](LICENSE).
